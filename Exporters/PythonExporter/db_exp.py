import csv
import configparser
import os
import argparse
import datetime
import shutil

def mssql_connect(config):
    host = config['mssql']['host']
    port = config['mssql']['port']
    database = config['mssql']['database']
    user = config['mssql']['user']
    pwd = config['mssql']['pwd']

    constr = 'DRIVER={SQL Server};SERVER='+host+';DATABASE='+database+';PORT='+port+';UID='+user+';PWD='+ pwd
    conn = pyodbc.connect(constr)
    return(conn)

def oracle_connect(config):
    host = config['oracle']['host']
    port = config['oracle']['port']
    sid = config['oracle']['sid']
    user = config['oracle']['user']
    pwd = config['oracle']['pwd']

    dsn_tns = cx_Oracle.makedsn(host, port, sid)
    conn = cx_Oracle.connect(user, pwd, dsn_tns)
    return(conn)

def parse_sql(sql_fname,sql_params):
    exports = []
    sql = ""
    output_file_tag = "OUTPUT_FILE:"
    output_file = None

    with open(sql_fname,"r") as inf:
        inrows = inf.readlines()

    block = False
    for row in inrows:
        if (row.strip().startswith('--') == True) and (row.find(output_file_tag) < 0):
            continue
        # replace sql params
        for param in sql_params:
            row = row.replace(param['tag'], param['value'])

        if row.strip().upper().startswith('BEGIN'):
            block = True;

        sql = sql + row
        if row.find(output_file_tag) >= 0:
            output_file = row[ row.find(output_file_tag) + len(output_file_tag):].strip()

        if block == True:
            if row.strip().upper().startswith('END;'):
                if output_file != None:
                    exports.append({"output_file": output_file, "sql":sql })
                else:
                    exports.append({"sql":sql })
                sql = ""
                block = False

        else:
            if row.find(';') >= 0:
                sql = sql.split(';')[0]
                if output_file != None:
                    exports.append({"output_file": output_file, "sql":sql })
                else:
                    exports.append({"sql":sql })
                sql = ""

    return(exports)

def create_phenotype(conn, phenotype_fname, sql_params):
    cursor=conn.cursor()
    sql_arr = parse_sql(phenotype_fname, sql_params)

    #print and return
    for sql in sql_arr:
        print(sql['sql'])
        cursor.execute(sql['sql'])
        conn.commit()

def db_export(conn, sql, csvwriter, arraysize):
    cursor=conn.cursor()
    cursor.arraysize = arraysize

    cursor.execute(sql);
    header = [column[0] for column in cursor.description]
    csvwriter.writerow(header)

    while True:
        rows = cursor.fetchmany()
        if not rows:
            break
        for row in rows:
            csvwriter.writerow(row)

    outf.close()
    cursor.close()

def test_env(database=None, sftp=None):
    import subprocess
    import sys
    db_req_packages = {'oracle': 'cx-Oracle', 'mssql': 'pyodbc'} # DB Specific Packages
    reqs = subprocess.check_output([sys.executable, '-m', 'pip', 'freeze'])
    installed_packages = [r.decode().split('==')[0] for r in reqs.split()]

    err_mess = ''
    if database != None: #test db packages
        if database not in db_req_packages:
            err_mess = err_mess + "Invalid database type, use mssql or oracle\n"
        else:
            if db_req_packages[database] not in installed_packages:
                err_mess = err_mess + "Package not installed for database connection: {}\n".format(db_req_packages[database])

    if sftp != None:
        if 'paramiko' not in installed_packages:
                err_mess = err_mess + "Package not installed for sftp: {}\n".format('paramiko')

    return(err_mess)

# get command line args
clparse = argparse.ArgumentParser(description='Export from DB using formatted SQL file, optionally create n3c_cohort table')
clparse.add_argument('--sql', required=False, default=None, help='name of the file that contains the export sql, must meet format spec, including ";" and OUTPUT_FILE:')
clparse.add_argument('--config', required=True, help='name of the configuration ini file')
clparse.add_argument('--database', required=False, default=None, help='oracle or mssql')
clparse.add_argument('--output_dir', default=".", help='csv files will be exported to this directory and this directory will be zipped if the zip option is set')
clparse.add_argument('--arraysize', default="10000", help='cursor array size, must be integer. This is how many records are fetched at once from DB, if you run into memory issues reduce this number')
clparse.add_argument('--phenotype', default=None, help='name of the file that contains the phenotype sql.  this will create the n3c_cohort table')
clparse.add_argument('--zip', default=None, help='create zip of output data files, no argument required', action='store_true')
clparse.add_argument('--sftp', default=None, help='sftp zip file, setup credentials and server in config file, no argument required', action='store_true')
args = clparse.parse_args()

output_dir = args.output_dir
sql_fname = args.sql
config_fname = args.config
database = args.database
arraysize = int(args.arraysize)
phenotype_fname = args.phenotype
create_zip = args.zip
sftp_zip = args.sftp

config = configparser.ConfigParser()
config.read(config_fname)

env_err = test_env(database, sftp_zip) 
if env_err != '':
    print('Failed Initialization Tests')
    print(env_err)
    exit()

# sql params
sql_params = [
    {'tag': '@resultsDatabaseSchema', 'value': config['sql']['results_database_schema']},
    {'tag': '@cdmDatabaseSchema', 'value': config['sql']['cdm_database_schema']},
    {'tag': '@vocabularyDatabaseSchema', 'value': config['sql']['cdm_database_schema']}
]

db_conn = None
if database == 'oracle':
    import cx_Oracle
    db_conn = oracle_connect(config)
elif database == 'mssql':
    import pyodbc
    db_conn = mssql_connect(config)
elif database != None:
    print("Invalid database type, use mssql or oracle")
    exit()

# PHENOTYPE #
# create phenotype table, n3c_cohort, if option set
if phenotype_fname != None:
    if db_conn == None:
        print("Invalid database type, use mssql or oracle")
        exit()
    print("Creating phenotype")
    create_phenotype(db_conn, phenotype_fname, sql_params)

# EXPORT #
if sql_fname != None:
    print("Exporting data")
    if db_conn == None:
        print("Invalid database type, use mssql or oracle")
        exit()
    # put domain data in DATAFILES subdir of output directory
    datafiles_dir = output_dir + os.path.sep + 'DATAFILES'
    # put files below in root output directory
    root_files = ('MANIFEST.csv','DATA_COUNTS.csv')
    # test for DATAFILES subdir exists
    if not os.path.exists(datafiles_dir):
        print("ERROR: export path not found {}.  You may need to create a 'DATAFILES' subdirectory under your output directory, also may need to specify --output on command line\n".format(datafiles_dir) )
        exit()
    exports = parse_sql(sql_fname,sql_params)
    for exp in exports:
        if 'output_file' in exp:
            output_file = exp['output_file']
        else:
            print("ERROR: output_file not found in sql block")
            exit()
        print( "processing output file: {}\n".format(output_file) )
        if output_file in root_files:
            outfname = output_dir + os.path.sep + exp['output_file']
        else:
            outfname = datafiles_dir + os.path.sep + exp['output_file']
        outf = open(outfname, 'w', newline='')
        csvwriter = csv.writer(outf, delimiter='|', quotechar='"', quoting=csv.QUOTE_ALL)
        db_export(db_conn, exp['sql'], csvwriter, arraysize)

# ZIP #
zip_prefix = config['site']['name'] + '_' + config['site']['cdm'] + '_' + datetime.date.today().strftime("%Y%m%d")
zip_fname = zip_prefix + ".zip"

if create_zip == True:
    print('Zipping ' + zip_fname)
    shutil.make_archive(zip_prefix, 'zip', output_dir)

# SFTP #
if sftp_zip == True:
    print("sftp zip file {}\n".format(zip_fname))
    #python -m pip install paramiko
    import paramiko
    paramiko.util.log_to_file("sftp.log")

    # open paramiko transport
    hp = config['sftp']['host'] + ':' + config['sftp']['port']
    transport = paramiko.Transport(hp)
    # authenticate
    transport.connect(None,config['sftp']['user'],config['sftp']['pwd'])
    # sftp client
    sftp = paramiko.SFTPClient.from_transport(transport)
    sftp.chdir(config['sftp']['remote_dir'])
    sftp.put(zip_fname,zip_fname)
