import re
import sys
import json
import subprocess

def cleanup(s):
    s = re.sub('(. )\1{9,}', '', re.sub('\s+', ' ', (
       s.replace('{', ' { ')
        .replace('}', ' } ')
        .replace('$', ' $ ')
        .replace('.', ' . ')
        .replace('/', ' / ')
        .replace('\\', ' \\ ')
        .replace('_', ' ')
        .replace('-', ' ')
        .replace("'", ' ')
        .replace('"', ' ')
        .replace('`', ' ')
        .replace('@', ' @ ')
        .replace('!', ' ! ')
        .replace('|', ' | ')
        .replace(';', ' ; ')
        .replace('[', ' [ ')
        .replace(']', ' ] ')
        .replace(':', ' : ')
        .replace('=', ' = ')
        .replace('~', ' ~ ')
        .replace('#', ' # ')
        .replace('*', ' * ')
        .replace('&', ' & ')
        .replace('(', ' ( ')
        .replace(')', ' ) ')
        .replace(',', ' , ')
        .replace('?', ' ? ')
        .replace('<', ' < ')
        .replace('>', ' > ')
        .replace('+', ' + ')
    )))

    return s

for line in sys.stdin:
    try:
        log_name = line.strip()
        print >> sys.stderr, log_name
        log_std_name = log_name.replace('build-log-stderr.txt', 'build-log-stdout.txt')
        dfile_name = log_name.replace('build-log-stderr.txt', 'Dockerfile')
        meta_name = log_name.replace('build-log-stderr.txt', 'meta.json')
        files_list = log_name.replace('build-log-stderr.txt', 'all-files.txt')
        dirs_list = log_name.replace('build-log-stderr.txt', 'all-directories.txt')
        json_res = {}
        with open(log_name, 'r') as fh:
            json_res['raw_stderr_log'] = fh.read().strip()
            lines = [ cleanup(x.strip().lower()) for x in fh.readlines() ]
            json_res['clean_stderr_log'] = lines
        with open(log_std_name, 'r') as fh:
            json_res['raw_stdout_log'] = fh.read().strip()
            lines = [ cleanup(x.strip().lower()) for x in fh.readlines() ]
            json_res['clean_stdout_log'] = lines
        with open(dfile_name, 'r') as fh:
            json_res['raw_dockerfile'] = fh.read().strip()
            lines = [ cleanup(x.strip().lower()) for x in fh.readlines() ]
            json_res['clean_dockerfile'] = lines
        with open(meta_name, 'r') as meta:
            json_res['meta'] = json.loads(meta.read())
        with open(files_list, 'r') as fh:
            json_res['files_in_repo'] =  [ x.strip() for x in fh.readlines() ]
        with open(dirs_list, 'r') as fh:
            json_res['dirs_in_repo'] =  [ x.strip() for x in fh.readlines() ]
        json_res['parsed_dockerfile'] = json.loads(subprocess.check_output(
            [ './binnacle-remote.sh', dfile_name ],
            input=json.dumps(ast1).encode('utf-8')
        ).decode('utf-8'))
        print(json.dumps(json_res))
    except Exception as ex:
        print(ex)
        continue
