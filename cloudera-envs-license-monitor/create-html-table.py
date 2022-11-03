# Run as: create-html-table.py {input-file-name}
# The script requires 1 argument: the input file name.
# It expects a comma-separated input file to parse into an html table,
# and assumes that the column headers are located in the first row.

import sys

filein = open(sys.argv[1], "r")
fileout = open("html-table.html", "w")
data = filein.readlines()
#Add border and style to HTML table
fileout.write("<html>\n")
fileout.write("<head>\n")
fileout.write("<style>\n")
fileout.write("table{\n")
fileout.write("  width: 60%;\n")
fileout.write("  border: 1px solid black;\n")
fileout.write("  border-collapse: collapse;\n")
fileout.write("  background-color: #66ffcc;\n")
fileout.write("}\n")
fileout.write("th, td {\n")
fileout.write("  width: 15%;\n")
fileout.write("  border: 1px solid black;\n")
fileout.write("  border-collapse: collapse;\n")
fileout.write("  background-color: #66ffcc;\n")
fileout.write("}\n")
fileout.write("</style>\n")
fileout.write("</head>\n")
fileout.write("<body>\n")


table = "<table>\n"
# Create the table's column headers
header = data[0].split(",")
table += "  <tr>\n"
for column in header:
    table += "    <th>{0}</th>\n".format(column.strip())
table += "  </tr>\n"

# Create the table's row data
for line in data[1:]:
    row = line.split(",")
    table += "  <tr>\n"
    for column in row:
        table += "    <td>{0}</td>\n".format(column.strip())
    table += "  </tr>\n"

table += "</table>"

fileout.writelines(table)
fileout.close()
filein.close()
