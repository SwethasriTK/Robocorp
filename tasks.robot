*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Excel.Application
Library             RPA.Tables
Library             RPA.Archive
Library             XML
Library             RPA.RobotLogListener
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Intializing steps
    Open the intranet website
    Log in
    Open the robot order website
    Download the Excel file
    Loop through csv file datas
    Merge screenshot with PDF
    Make Output pdf as Zip


*** Keywords ***
Remove and add empty directory
    [Arguments]    ${folder}
    Remove Directory    ${folder}    True
    Create Directory    ${folder}

Intializing steps
    Remove File    ${CURDIR}${/}orders.csv
    ${reciept_folder}=    Does Directory Exist    ${CURDIR}${/}receipts
    ${robots_folder}=    Does Directory Exist    ${CURDIR}${/}robots
    IF    '${reciept_folder}'=='True'
        Remove and add empty directory    ${CURDIR}${/}receipts
    ELSE
        Create Directory    ${CURDIR}${/}receipts
    END
    IF    '${robots_folder}'=='True'
        Remove and add empty directory    ${CURDIR}${/}robots
    ELSE
        Create Directory    ${CURDIR}${/}robots
    END

Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/
    Maximize Browser Window

Log in
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Open the robot order website
    Click Element    //li[2]/a
    Wait Until Element Is Visible    //div[2]/div/div/div
    Click Button    //button[contains(.,'OK')]

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Close and start Browser prior to another transaction
    Close Browser
    Open the intranet website
    Continue For Loop

Checking Receipt data processed or not
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${alert}'=='True'    Click Button    //button[@id="order"]
        IF    '${alert}'=='False'            BREAK
    END

    IF    '${alert}'=='True'
        Close and start Browser prior to another transaction
    END

Fill and Submit the form
    [Arguments]    ${order}
    Wait Until Element Is Visible    //div[@id='root']/div
    Select From List By Index    //select[@id='head']    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep    5 seconds
    Click Button    order
    Sleep    5 seconds
    Checking Receipt data processed or not
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    id:receipt
    Screenshot
    ...    id:robot-preview-image
    ...    ${CURDIR}${/}robots${/}${order}[Order number].png
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf
    ...    ${receipt_html}
    ...    ${CURDIR}${/}receipts${/}${order}[Order number].pdf
    Open Pdf    ${CURDIR}${/}receipts${/}${order}[Order number].pdf
    Close Pdf
    Click Button    order-another
    Click Button    //button[contains(.,'OK')]

Loop through csv file datas
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill and submit the form    ${order}
    END

Merge screenshot with PDF
    FOR    ${counter}    IN RANGE    1    20
        Open Pdf    ${CURDIR}${/}receipts${/}${counter}.pdf
        Add Watermark Image To Pdf
        ...    ${CURDIR}${/}robots${/}${counter}.png
        ...    ${CURDIR}${/}receipts${/}${counter}.pdf
        Close Pdf    ${CURDIR}${/}receipts${/}${counter}.pdf
    END

Make output pdf as Zip
    Archive Folder With Zip    ${CURDIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
