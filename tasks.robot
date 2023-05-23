*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the screenshot of the ordered robot.
...               Saves the order HTML receipt as a PDF file.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               Delete receipts and pics folder when all is done.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download robot order CSV
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Press Order Button
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${row[Order number]}
    Wait Until Element Is Visible    id:receipt
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${row[Order number]}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}receipt_${row[Order number]}.pdf

Take a screenshot of the robot
    [Arguments]    ${row[Order number]}
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}pics${/}robotPic_${row[Order number]}.png
    [Return]    ${OUTPUT_DIR}${/}pics${/}robotPic_${row[Order number]}.png
    
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    ${files}=    Create List
    ...    ${pdf}:1
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}

Fill the form for one robot and order
    [Arguments]    ${orders}
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    ${screenshot}=    Take a screenshot of the robot    ${orders}[Order number]
    Wait Until Keyword Succeeds    10x    0.5 sec    Press Order Button
    ${pdf}=    Store the receipt as a PDF file    ${orders}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    id:order-another
    Pass the modal

Gather orders and pass them to order form
    ${orders}=    Read table from CSV    orders.csv    header=true
    FOR    ${orders}    IN    @{orders}
        Fill the form for one robot and order    ${orders}
    END

Pass the modal
    Wait Until Page Contains Element    css:div.modal-body
    Click Button    OK

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}

Cleanup temporary PDF and pics directory, close browser
    Remove Directory    ${OUTPUT_DIR}${/}receipts    True
    Remove Directory    ${OUTPUT_DIR}${/}pics    True
    Close Browser

*** Tasks ***
Minimal task
    Open the robot order website
    Pass the modal
    Download robot order CSV
    Gather orders and pass them to order form
    Create ZIP package from PDF files
    [Teardown]    Cleanup temporary PDF and pics directory, close browser
    Log    Done.
