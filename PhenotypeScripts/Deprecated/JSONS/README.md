Background
=============
This purpose of this folder is to provide OHDSI collaborators JSON files that can be loaded into a local ATLAS instance.

The JSON reflecting the Latest Phenotype is available in N3C_phenotype_v1_5 (issue [#321](https://github.com/OHDSI/Vocabulary-v5.0/issues/321) raised to report missing concepts to be compliant with v1_6).

We have also constructed JSONS to identify lab-confirmed positive cases, lab-confirmed negative cases, suspected positive and possible positive. The purposes of these individual JSONs is to allow local data custodians to be able to check counts against known figures reported for public health reporting.

Instructions
=============
1. To load a JSON file into your local ATLAS, open your local ATLAS. Navigate down the left hand panel to 'Cohort Definition' and click to open this page.
2. In the Cohort Definition page, click the button that says 'New Cohort' (on the left side of the page).
3. In the New Cohort Definition page, you will have to enter a name in the 'New Cohort Definition' text field. This will be the name of the Cohort in your environment (e.g. [CD2H] Covid-19 Phenotype Version 1.5). Make sure to hit the save button (aka the green floppy disk icon).
4. Once you have saved a cohort with a name, you will see a Cohort ID# assigned to your record.
5. From here, you can now import your JSON file by navigating to the 'Export' tab. Click on the 'Export' tab and click on 'JSON'.
6. In this box, you can select-all in the box and delete the text that's present. Then paste the JSON you copied from GitHub.
7. Once you have pasted the JSON code, you need to hit 'Reload' (in the lower left corner). This will now apply the JSON logic to the cohort.
8. You'll see the save icon become active again. You should hit save to retain this update.
9. To confirm this import is complete, navigate to the 'Definition' tab. You will see the Cohort Entry event populated with the entry criteria for this cohort.

If you have any questions, please feel free to reach out to [Kristin Kostka](mailto:kristin.kostka@iqvia.com).
