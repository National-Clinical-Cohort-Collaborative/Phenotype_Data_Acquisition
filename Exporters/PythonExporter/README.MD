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

You can (optionally) use our Python Data Exporter to run the N3C data extract SQL scripts in sequence, basically hands-free. You can schedule this to run as a cron job if you’d like to use it to dump your data on a recurring basis.

**System Prerequisites**



*   Python 3.x
*   Oracle or MS SqlServer
*   If you are using MS SqlServer, you will need to have package pyodbc installed (pip install pyodbc)
*   If you are using Oracle, you will need to have package cx_Oracle installed (pip install cx_Oracle) as well as the Oracle client libraries.  [More information about cx_Oracle installation](https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html)
*   To use the sftp feature, you may need to install paramiko:  python -m pip install paramiko
*   You should have already copied one of the [extract SQL files](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/ExtractScripts) and [phenotype SQL file](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/PhenotypeScripts) to a local directory.

**Running the Exporter**



1. Copy or download the contents of this folder to your local system. To make it easy, use the same directory where your extract SQL and phenotype SQL files are located.
2. You may need to edit the extract SQL and phenotype SQL for the queries to work on your local system. 
3. Use the "config_ini_example.txt" file to create your own configuration.  You will want to edit your config file and enter in information for database connection, sftp connection and zip file create (site).
4. Run the following command, replacing the arguments with whatever options make sense for your environment. You don't have to specify all options when you run, you can leave of the --zip, --sftp, --phenotype or --extract if you don't want to perform those operations.


```
python db_exp.py --config config.ini --database oracle --phenotype N3C_phenotype_V1_0_act_oracle.sql --extract N3C_extract_V1_0_act_oracle.sql --output_dir E:\N3C --zip --sftp
```
**NLP Sites - Running the Exporter**

For NLP sites you will need to use two extract scripts, one for the core tables and one for the NLP tables.  To run two extract scripts you will need to break up the process into multiple steps:
1. Run the phenotype
2. Extract the core tables
3. Extract the NLP tables
4. ZIP the files
5. SFTP the payload

Example:
```
python db_exp.py --config config.ini --database oracle --output_dir E:\N3C --phenotype N3C_phenotype_V1_0_act_oracle.sql
python db_exp.py --config config.ini --database oracle --output_dir E:\N3C --extract N3C_extract_V1_0_act_oracle.sql
python db_exp.py --config config.ini --database oracle --output_dir E:\N3C --extract N3C_extract_nlp_oracle.sql
python db_exp.py --config config.ini --database oracle --output_dir E:\N3C --zip 
python db_exp.py --config config.ini --database oracle --output_dir E:\N3C --sftp
```
**OMOP Sites -  Exporting visit_detail for ADT data**

For sites that need to export the OMOP visit_detail table for ADT data, you will need to use two extract scripts.  One extract script for the core tables and another for the visit_detail table.  See "NLP Sites - Running the Exporter" example above for running multiple extract scripts.

**Script Command Line Options**


*   --help
*   --config (config file name)  See file "config_example.ini"
*   --phenotype (phenotype SQL file name)
*   --extract (extract SQL file name)
*   --database (oracle or mssql)
*   --output_dir (output directory for export)   Output directory must have a sub-directory "datafiles".
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
