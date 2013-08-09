#!/usr/bin/env python

import os, sys, subprocess

log = 'build.log'
sep = '-------------------------------------------------------------------------------'

if len(sys.argv) < 1:
    base = '/work/kernel/jenkins/jobs/kernel-flex/workspace'
    prefix = 'build-'
    rev = subprocess.check_output('git describe', shell=True)[:-1]
    dir = os.path.join(base, prefix + rev)
else:
    dir = sys.argv[1]
    base = os.path.dirname(dir)

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

# Parse the logs
for build in os.listdir(dir):
    if not '-' in build:
        continue

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
        
    err_cmd = 'fgrep -i error: %s | ' \
        'sed "s@.*%s/@@g"' %(buildlog, base)
    errors = subprocess.check_output(err_cmd, shell=True).splitlines()
    for e in errors:
        errors_all[e] = errors_all.setdefault(e, 0) + 1

    warn_cmd = 'fgrep warning: %s | ' \
        'fgrep -v "TODO: return_address should use unwind tables" | ' \
        'fgrep -v "NPTL on non MMU needs fixing" | ' \
        'fgrep -v "Sparse checking disabled for this file" | ' \
        'sed "s@.*%s/@@g"' %(buildlog, base)
    warnings = subprocess.check_output(warn_cmd, shell=True).splitlines()
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

# Print report
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

# per-build report
print
print "per-defconfig results:"
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


# Any errors means we should report failure
retval = 0
if fail_count:
    retval = 1

sys.exit(retval)
