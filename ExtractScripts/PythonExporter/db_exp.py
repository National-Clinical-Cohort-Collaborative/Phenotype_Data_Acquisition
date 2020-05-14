import csv
import configparser
import os
import argparse
import datetime
import time

def mssql_connect(config):
    host = config['mssql']['host']
    port = config['mssql']['port']
    database = config['mssql']['database']
    user = config['mssql']['user']
    pwd = config['mssql']['pwd']

    constr = 'DRIVER={SQL Server};SERVER='+host+';DATABASE='+database+';UID='+user+';PWD='+ pwd
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

def parse_sql(input_sql):
    exports = []
    sql = ""
    output_file_tag = "OUTPUT_FILE:"
    output_file = None

    with open(sql_fname,"r") as inf:
        inrows = inf.readlines()
    for row in inrows:
        sql = sql + row
        if row.find(output_file_tag) >= 0:
            output_file = row[ row.find(output_file_tag) + len(output_file_tag):].strip()

        if row.find(';') >= 0:
            sql = sql.split(';')[0]
            exports.append({"output_file": output_file, "sql":sql })
            sql = ""

    return(exports)


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

# get command line args
clparse = argparse.ArgumentParser(description='Export from DB using formatted SQL file')
clparse.add_argument('--sql', required=True, help='name of sql file to use for export, must meet format spec, including ; and OUTPUT_FILE:')
clparse.add_argument('--database_ini', required=True, help='name of database ini file')
clparse.add_argument('--database_type', required=True, help='oracle or mssql')
clparse.add_argument('--output_dir', default=".", help='csv files will be exported to this directory')
clparse.add_argument('--arraysize', default="10000", help='cursor array size, must be integer. This is how many records are fetched at once from DB, if you run into memory issues reduce this number')
args = clparse.parse_args()
if args.sql == None:
    print("invalid input, type <programfile> -h for usage")
    exit()

output_dir = args.output_dir
sql_fname = args.sql
database_ini = args.database_ini
database = args.database_type
arraysize = int(args.arraysize)

exports = parse_sql(sql_fname)

if database == 'oracle':
    import cx_Oracle
    config = configparser.ConfigParser()
    config.read(database_ini)
    db_conn = oracle_connect(config)
elif database == 'mssql':
    import pyodbc
    config = configparser.ConfigParser()
    config.read(database_ini)
    db_conn = mssql_connect(config)
else:
    print("Invalid database type, use mssql or oracle")
    exit()

# put domain data in datafiles subdir of output directory
datafiles_dir = output_dir + os.path.sep + 'datafiles'
# put files below in root output directory
root_files = ('MANIFEST.csv','DATA_COUNTS.csv')
# test for datafiles subdir exists
if not os.path.exists(datafiles_dir):
    print("ERROR: path not found {}\n".format(datafiles_dir) )
    exit()

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
