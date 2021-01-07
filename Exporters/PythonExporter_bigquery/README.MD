<!-----
NEW: Your output is on the clipboard!

NEW: Check the "Supress top comment" to remove this info from the output.

Conversion time: 0.423 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0?23
* Tue May 12 2020 10:08:49 GMT-0700 (PDT)
* Source doc: Untitled document
----->


**Python Data Exporter**

You can (optionally) use our Python Data Exporter to run the N3C data extract scripts in sequence, basically hands-free. You can schedule this to run as a cron job if you’d like to use it to dump your data on a recurring basis.

**System Prerequisites**



*   Python 3.x
*   Oracle, MS SqlServer, or Google BigQuery
*   If you are using MS SqlServer or Google BigQuery, you will need to have package pyodbc installed (pip install pyodbc)
*   If you are using Oracle, you will need to have package cx_Oracle installed (pip install cx_Oracle) as well as the Oracle client libraries.  [More information about cx_Oracle installation](https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html)
*   To use the sftp feature, you may need to install paramiko:  python -m pip install paramiko
*   You should have already copied one of the [extract SQL files](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/ExtractScripts) and [phenotype SQL file](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/PhenotypeScripts) to a local directory.
*	Google BigQuery requires installation of Simba ODBC drivers (https://cloud.google.com/bigquery/providers/simba-drivers)

**Running the Exporter**


1. Copy or download the contents of this folder to your local system. To make it easy, use the same directory where your extract SQL and phenotype SQL files are located.
2. You may need to edit the extract SQL and phenotype SQL for the queries to work on your local system. 
3. Use the "config_ini_example.txt" file to create your own configuration.  You will want to edit your config file and enter in information for database connection, sftp connection and zip file create (site).
4. Run the following command, replacing the arguments with whatever options make sense for your environment. You don't have to specify all options when you run, you can leave of the --zip, --sftp, --phenotype or --extract if you don't want to perform those operations.


```
python db_exp.py --config config.ini --database oracle --phenotype N3C_phenotype_V1_0_act_oracle.sql --extract N3C_extract_V1_0_act_oracle.sql --output_dir E:\N3C --zip --sftp
```

**Script Command Line Options**


*   --help
*   --config (config file name)  See file "config_example.ini"
*   --phenotype (phenotype SQL file name)
*   --extract (extract SQL file name)
*   --database (oracle, mssql, or bigquery)
*   --output_dir (output directory for export)   Output directory must have a sub-directory "datafiles".
*   --storedata Stores all data files in local DBMS
*   --storevocab Stores current vocabulary files in local DBMS
*   --nocsv Runs extract script but does not write CSV. If --storedata, data stored only in local DBMS.
*   --zip
*   --sftp
*   --debug

**What will my output look like?**

Once you run the exporter, your files will be output in the following directory structure:

**_Parent Directory_**

![Screenshot of Example Parent Directory](https://imgur.com/68YwCGU.png)


**_Sub-Directory_**

![Screenshot of Example Sub-Directory](https://imgur.com/ubrdNwA.png)

(These are OMOP files--if you use PCORnet or ACT, your exported tables will have different names/quantity, but will be in the same directly structure.) Note that these files are .csv files, but are actually pipe delimited rather than comma delimited. The exporter will take care of delimiters, formatting, headers, and everything else you need to be compliant with our formatting.

**Bug Reports/Enhancement Requests/Contributions**

We would love to hear from you about this script, as we hope to continue to improve and enhance it. We also welcome contributions, if there’s a cool feature you’ve added locally. Please feel free to open an issue or create a pull request as needed!

