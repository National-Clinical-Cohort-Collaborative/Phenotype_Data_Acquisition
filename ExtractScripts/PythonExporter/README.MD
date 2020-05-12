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
*   You should have already copied one of the [extract SQL files](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition/tree/master/ExtractScripts) to a local directory.

**Running the Exporter**



1. Copy or download the contents of this folder to your local system. To make it easy, use the same directory where your extract SQL file is located.
2. In the “database_example” file, fill in the details of your database connection. (You can change the name of this file to whatever makes sense for you.) Right now, we support Oracle and SQL Server. 
3. Run the following command, replacing the arguments with whatever options make sense for your environment. 


```
python db_exp.py --sql N3C_extract_V1_0_act_oracle.sql --database_type oracle --database_ini database_example.ini --output_dir E:\N3C
```


**Bug Reports/Enhancement Requests/Contributions**

We would love to hear from you about this script, as we hope to continue to improve and enhance it. We also welcome contributions, if there’s a cool feature you’ve added locally. Please feel free to open an issue or create a pull request as needed!
