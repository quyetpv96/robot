*** Settings ***
Resource    ../Resource/Common.resource
Suite Setup     Test-precondition
Suite Teardown      Test-postCondition
Test Timeout    5m


*** Variables ***
${Phone_Name}   Galaxy S7 edge
${A}        abc
${youtube}      ./TestCase/DB_file/YouTube.png

*** Test Cases ***
Verify About Phone
    [Documentation]     Verify phone name

    Connect Adb server    ${DEVICE_SERIAL}
#    ${result}   ${call_count}=      FIND_IMAGE_AND_TOUCH_IT    ${youtube}    ${CALL_COUNT}
#    ${result}   ${call_count}=      FIND_STRING_ON_SCREEN_AND_TOUCH_IT    YouTube    ${CALL_COUNT}

    Log To Console    Go To Android Settings
    Run    adb -s ${DEVICE_SERIAL} shell am start -a android.settings.SETTINGS
    Sleep    2

    Log To Console    Scroll to about phone
    UI.Scroll into view    ${DEVICE_SERIAL}    About phone
    Sleep    2

    Log To Console    Click about phone
    Click by text    ${DEVICE_SERIAL}    About phone

    Sleep    2

    Log To Console    Check the phone name on screen
    ${result}=     Find text on screen     ${DEVICE_SERIAL}    ${Phone_Name}
    Run Keyword If    '${result}' == 'True'  Log    The Phone name correct
    Run Keyword If    '${result}' == 'False'     Run Keyword And Return    Fail  The Phone name incorrect
    Sleep    2

    Log To Console    Go home
    Run    adb -s ${DEVICE_SERIAL} shell input keyevent 3



    


