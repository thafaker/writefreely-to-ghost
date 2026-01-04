# writefreely-to-ghost

I wrote a Script to convert the Writefreely Export JSON File to Ghost Import JSON File

## Just a few steps

clone this repo to your Linux Distribution

    git clone https://github.com/thafaker/writefreely-to-ghost.git

You need Pandoc for the converstion of the Writefreely-Markdown to the HTML Code Ghost needs for the Import.

    brew install pandoc

or

    apt install pandoc

or

    yes, you name it…

Than copy your writefreely export json file into this cloned folder and rename it to writefreely-export.json

Make the script executable

    chmod +x convert-writefreely-to-ghost.sh

Run the script

    ./convert-writefreely-to-ghost.sh

Depending on the amount of Posts you have, it takes a little bit of time. After that you should get a file named <code>ghost-import-complete.json</code> and this can be imported via webinterface into your ghost installation.

Hope that helps.
Jan
