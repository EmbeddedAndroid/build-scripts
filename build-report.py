#!/usr/bin/env python
#
# Usage: build-report <base>
# 
#   Where <base> is the root directory containing all the build output
#
import os, sys, subprocess
import tempfile, getopt

log = 'build.log'
sep = '-' * 79

mail_to = None

def usage():
    print "Usage: %s [-m <email address>] <base>" %(sys.argv[0])

try:
    opts, args = getopt.getopt(sys.argv[1:], "m:")
except getopt.GetoptError as err:
    print str(err)
    usage()
    sys.exit(1)

for o, a in opts:
    if o == '-m':
        mail_to = a

if len(args) < 1:
    usage()
    sys.exit(1)

dir = os.path.abspath(args[0])
base = os.path.abspath(os.path.dirname(dir))

if not os.path.exists(dir):
    print "ERROR: %s does not exist" %dir

# format: (result, error list, warning list, mismatch list)
report = {}

pass_count = 0
fail_count = 0
total_count = 0
warnings_all = {}
mismatch_all = {}
errors_all = {}

def uniqify(d):
    l = zip(d.values(), d.keys())
    l.sort()
    l.reverse()
    return l

def remove_prefix(arr, base):
    """Remove string <base> from beginning of each array element"""
    for i in range(len(arr)):
        if arr[i].find(base, 0) == 0:
            arr[i] = arr[i][len(base) + 1:]

# Parse the logs
for build in os.listdir(dir):

    buildlog = os.path.join(dir, build, log)
    # Ignore build dirs with no build log
    if not os.path.exists(buildlog):
        continue

    total_count += 1

    pass_file = os.path.join(dir, build, 'PASS')
    if os.path.exists(pass_file):
        pass_fail = 'PASS'
        pass_count += 1
    else:
        pass_fail = 'FAIL'
        fail_count += 1
        
    # Error messages, strip of the path prefix
    err_cmd = 'grep [Ee]rror: %s | cat' %buildlog
    errors = subprocess.check_output(err_cmd, shell=True).splitlines()
    remove_prefix(errors, base)

    # Some errors start with ERROR:
    # DTB compiler gives 'ERROR' (without trailing :)
    err_cmd = 'grep ^ERROR %s | cat' %buildlog
    errors2 = subprocess.check_output(err_cmd, shell=True).splitlines()
    for e in errors2:
        errors.append(e)

    for e in errors:
        errors_all[e] = errors_all.setdefault(e, 0) + 1

    warn_cmd = 'fgrep warning: %s | ' \
        'fgrep -v "TODO: return_address should use unwind tables" | ' \
        'fgrep -v "NPTL on non MMU needs fixing" | ' \
        'fgrep -v "Sparse checking disabled for this file" | cat' %buildlog
    warnings = subprocess.check_output(warn_cmd, shell=True).splitlines()
    remove_prefix(warnings, base)
    for w in warnings:  
        warnings_all[w] = warnings_all.setdefault(w, 0)  + 1

    mismatch_cmd = 'fgrep "Section mismatch" %s | cat' %(buildlog)
    mismatches = subprocess.check_output(mismatch_cmd, shell=True).splitlines()
    for m in mismatches:
        mismatch_all[m] = mismatch_all.setdefault(m, 0) + 1

    report[build] = (pass_fail, errors, warnings, mismatches)


if total_count == 0:
    print "No builds found."
    sys.exit(0)

# Calculate Summaries
errors = uniqify(errors_all)
error_count = len(errors)
warns = uniqify(warnings_all)
warning_count = len(warns)
mismatches = uniqify(mismatch_all)
mismatch_count = len(mismatches)

report_header = 'report_header.txt'  # Created by Jenkins for tree/branch info
try:
    f = open(report_header, 'r')
    line = f.readline().rstrip()
    if line.startswith('Tree/Branch:'):
        (key, val) = line.split(':')
        tree_branch = val.strip()
except IOError:
    tree_branch = None

if os.path.exists('.git'):
    describe = subprocess.check_output('git describe', shell=True).rstrip()
    commit = subprocess.check_output('git log -n1 --oneline --abbrev=10',
                                     shell=True)

#
#  Log to a file as well as stdout (for sending with msmtp)
#
maillog = tempfile.mktemp(suffix='.log', prefix='build-report')
mail_headers = """From: khilman+build@linaro.org
To: %s
Subject: build %s: %d errors %d warnings %d mismatches (%s)

""" %(mail_to, tree_branch, error_count, warning_count, mismatch_count, describe)
if mail_to and maillog:
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0) # Unbuffer output
    tee = subprocess.Popen(["tee", "%s" %maillog], stdin=subprocess.PIPE)
    os.dup2(tee.stdin.fileno(), sys.stdout.fileno())
    os.dup2(tee.stdin.fileno(), sys.stderr.fileno())
    print mail_headers

# Print report
if tree_branch:
    print 'Tree/Branch:', tree_branch
if os.path.exists('.git'):
    print 'Git describe:', describe
    print 'Commit:', commit

formatter = "{:6.2f}"
print "Passed: %3d / %d   (%6.2f %%)" \
    %(pass_count, total_count, float(pass_count) / total_count * 100)
print "Failed: %3d / %d   (%6.2f %%)" \
    %(fail_count, total_count, float(fail_count) / total_count * 100)
print
print "Errors:", error_count
print "Warnings:", warning_count
print "Section Mismatches:", mismatch_count

# Build failure summary:
if fail_count:
    print
    print "Failed defconfigs:"
    for build in report:
        pass_fail = report[build][0]
        if pass_fail == 'FAIL':
            print "\t%s" %build
        
    print
    print "Errors:"
    for build in report:
        pass_fail = report[build][0]
        if pass_fail == 'PASS':
            continue

        err = report[build][1]
        if not len(err):
            continue

        print
        print "\t%s" %build
        for e in err:
            print e
    
print
print sep

# Errors Summary
if error_count:
    print
    print "Errors summary:", error_count
    for e in errors:
        print "\t%3d %s" %(e[0], e[1])

# Warnings Summary (for all builds)
if warning_count:
    print
    print "Warnings Summary:", warning_count
    for w in warns:
        print "\t%3d %s" %(w[0], w[1])

# Mismatch Summary (for all builds)
if mismatch_count:
    print
    print "Section Mismatch Summary:", mismatch_count
    for m in mismatches:
        print "\t%3d %s" %(m[0], m[1])

print "\n" * 4
print "=" * 79
print "Detailed per-defconfig build reports below:"
print

# per-build report
for build in report:
    pass_fail = report[build][0]
    errors = report[build][1]
    warnings = report[build][2]
    mismatches = report[build][3]

    print
    print sep
    print build, \
        ": %s, %d errors, %d warnings, %d section mismatches" \
        %(pass_fail, len(errors), len(warnings), len(mismatches))

    if len(warnings) or len(errors) or len(mismatches):
        if len(errors):
            print
            print "Errors:"
            for err in errors:
                print '\t', err

        if len(warnings):
            print
            print "Warnings:"
            for warn in warnings:
                print '\t', warn

        if len(mismatches):
            print
            print "Section Mismatches:"
            for m in mismatches:
                print '\t', m

print

# Mail the final report
if maillog and mail_to:
    subprocess.check_output('cat %s | msmtp -t --' %maillog, shell=True)

retval = 0
if fail_count:
    retval = 1

sys.exit(retval)