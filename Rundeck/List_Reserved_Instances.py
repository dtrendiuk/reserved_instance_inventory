#!/usr/bin/env python

# Libraries
import gspread
from datetime import date
from oauth2client.service_account import ServiceAccountCredentials

# Authorization
scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/drive",
]
credentials = ServiceAccountCredentials.from_json_keyfile_name(
    "/tmp/reserved_instances_inventory/reserved-instances-inventory.json", scope)
client = gspread.authorize(credentials)

# Variables definition
today = date.today()
curr_date = today.strftime("%m/%d/%y")
spreadsheet = client.open("List_Reserved_Instances")
worksheet = spreadsheet.add_worksheet(title=curr_date, rows="1000", cols="5")
curr_sheet = curr_date + '!' + 'A1'

# Import CSV Function


def ImportCsv(csvFile, sheet, cell):
    """
    csvFile - path to csv file to import
    sheet - a gspread.Spreadsheet object
    cell - string giving starting cell, optionally including sheet/tab name
      ex: 'A1', 'Sheet2!A1', etc.
    """
    if "!" in cell:
        (tabName, cell) = cell.split("!")
        wks = sheet.worksheet(tabName)
    else:
        wks = sheet.sheet1
    (firstRow, firstColumn) = gspread.utils.a1_to_rowcol(cell)

    with open(csvFile, "r") as f:
        csvContents = f.read()
    body = {
        "requests": [
            {
                "pasteData": {
                    "coordinate": {
                        "sheetId": wks.id,
                        "rowIndex": firstRow - 1,
                        "columnIndex": firstColumn - 1,
                    },
                    "data": csvContents,
                    "type": "PASTE_NORMAL",
                    "delimiter": ",",
                }
            }
        ]
    }
    return sheet.batch_update(body)


ImportCsv("/tmp/reserved_instances_inventory/List_Reserved_Instances.csv",
          spreadsheet, curr_sheet)
print("Check the list of the reserved instances at: https://docs.google.com/spreadsheets/d/...")
