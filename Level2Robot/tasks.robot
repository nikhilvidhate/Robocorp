*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipts as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and images.
Library           RPA.Browser.Selenium    auto_close=${False}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download orders file csv
    Open the Robot order website
    Log In
    Navigate to order robot tab
    Fill and submit form for multiple orders
    Create ZIP
    Logout and Close the Browser

*** Keywords ***
Download orders file csv
    Add heading    Download the CSV file    size=Large
    Add text input    name=URL    label=Enter the URL of the orders CSV file
    ${result}=    Run dialog    title=Input form
    Download    ${result.URL}    ${CURDIR}${/}output    overwrite=True

Open the Robot order website
    Open Available Browser    https://robotsparebinindustries.com    maximized=True

Log In
    ${secret}=    Get Secret    credentials
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form

Navigate to order robot tab
    Click Element    //html/body/div/header/div/ul/li[2]/a
    Click Button    OK

Fill and submit form for multiple orders
    ${orders}=    Read table from CSV    path=${CURDIR}${/}output${/}orders.csv    header=True
    FOR    ${orders}    IN    @{orders}
        Fill and submit the form for one order    ${orders}
        Receipt as PDF    ${orders}
        Insert robot image into PDF    ${orders}
        Click Element    order-another
        Click Button    OK
    END

Fill and submit the form for one order
    [Arguments]    ${orders}
    ${strHead}=    Convert To String    ${orders}[Head]
    ${strBody}=    Convert To String    ${orders}[Body]
    Select From List By Value    head    ${strHead}
    Select Radio Button    body    id-body-${strBody}
    Input Text    //html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    Preview
    Click Button    Order
    Check if receipt exists
    [Return]    ${orders}[Order number]

Check if receipt exists
    ${receiptSelector}=    Does Page Contain Element    receipt    count=${1}
    IF    ${receiptSelector} == True
        Log    True
    ELSE
        Click Button    order
        Check if receipt exists
        Log    Else
    END

 Receipt as PDF
    [Arguments]    ${orders}
    Wait Until Element Is Visible    id=receipt
    ${receipt}=    Get Element Attribute    id=receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}PDF_Files${/}${orders}[Order number].pdf

Insert robot image into PDF
    [Arguments]    ${orders}
    Wait Until Element Is Visible    id=robot-preview-image    timeout=5
    Capture Element Screenshot    id=robot-preview-image    ${CURDIR}${/}output${/}Robot_image.png
    ${file}=    Create List    ${CURDIR}${/}output${/}Robot_image.png
    Add Files To Pdf    ${file}    ${CURDIR}${/}output${/}PDF_Files${/}${orders}[Order number].pdf    True

Create ZIP
    Archive Folder With Zip    ${CURDIR}${/}output${/}PDF_Files    ${CURDIR}${/}output${/}PDF_Files.zip

Logout and Close the Browser
    Click Button    logout
    Close Browser
