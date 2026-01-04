# writefreely-to-ghost

I wrote a Script to convert the Writefreely Export JSON File to Ghost Import JSON File

## First Step

clone this repo to your Linux Distribution

    git clone https://github.com/thafaker/writefreely-to-ghost.git

You need Pandoc for the converstion of the Markdown in Writefreely to the HTML Ghost needs in den Import.

    brew install pandoc
    or
    apt install pandoc
    or
    yes, you name it

Than copy your writefreely file into this cloned folder and rename it to writefreely-export.json

Run the script

   bash convert-writefreely-to-ghost.sh

It take a little bit of time, after that you should got a file named ghost-import-complete.json and this can be imported via webinterface into your ghost installation.

Hope that helps.
Jan
