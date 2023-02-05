*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${pdf_temporary_directory}=             ${OUTPUT_DIR}${/}PDF_Temporary
${screenshot_temporary_directory}=      ${OUTPUT_DIR}${/}Screenshot_Temporary
${secret}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret_url}=    Get the value of the vault secrets
    Log    ${secret_url}
    Open Order Page    ${secret_url}
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Cleanup temporary directories
    Close the browser
    Log    Done.


*** Keywords ***
Get the value of the vault secrets
    ${secret}=    Get Secret    order_robots
    Log    ${secret}
    Log    ${secret}[url]
    RETURN    ${secret}[url]

Open Order Page
    [Arguments]    ${secret_url}
    Open Available Browser    ${secret_url}
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Sleep    0.5s
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    ${isOrderAnotherRobotButtonVisible}=    Is Element Visible    id:order-another
    WHILE    ${isOrderAnotherRobotButtonVisible} == False
        Click Button    Order
        ${isOrderAnotherRobotButtonVisible}=    Is Element Visible    id:order-another
        Sleep    0.5s
    END

Go to order another robot
    Wait Until Page Contains Element    id:order-another    timeout=30s
    Click Button    Order another robot

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    ${receiptHTML}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receiptHTML}    ${pdf_temporary_directory}${/}receipt_${orderNumber}.pdf
    RETURN    ${pdf_temporary_directory}${/}receipt_${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Screenshot    id:robot-preview-image    ${screenshot_temporary_directory}${/}screenshot_${orderNumber}.png
    RETURN    ${screenshot_temporary_directory}${/}screenshot_${orderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${screenshotList}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${screenshotList}    ${pdf}    True
    Close Pdf    ${pdf}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${pdf_temporary_directory}    ${zip_file_name}

Cleanup temporary directories
    Remove Directory    ${pdf_temporary_directory}    True
    Remove Directory    ${screenshot_temporary_directory}    True

Close the browser
    Close Browser
