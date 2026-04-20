*** Settings ***
Library     SeleniumLibrary
Library     OperatingSystem
Library     Process
Library     String
Library     ../Plugin/Android.py
Library     ../Plugin/Helper.py     WITH NAME   UI
Library     ../Plugin/compare/ImageCompare.py
Library     ../Plugin/PathUtils.py

*** Variables ***
${URL}     https://www.youtube.com
${DEVICE_SERIAL}    ce11160baddc4c2c04

${USER_AGENT}    user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0
@{OPTIONS}    ["--start-maximized","--disable-infobars","--disable-notifications","--disable-blink-features=AutomationControlled","--disable-gpu","--no-sandbox"]

${LOG_BASE_PATH}       ${CURDIR}/../LOG
${WORKSPACE_PATH}      tmp
${RESORCE_PATH}        ${CURDIR}
${REMOTE_SCREENSHOT_PATH}    /sdcard/screenshot.png
${CALL_COUNT}   0

*** Keywords ***
Test-precondition
    Log    Pre-condition
    ${parent_path}=    PathUtils.get_parent_directory    ${RESORCE_PATH}
    ${parent_path}=    Normalize Path    ${parent_path}
    Set Global Variable    ${WORKSPACE_PATH}    ${parent_path}

    ${LOG_SUITE_PATH}=    Join Path    ${LOG_BASE_PATH}    ${SUITE NAME}
    ${LOG_SUITE_PATH}=    Normalize Path    ${LOG_SUITE_PATH}
    Create Directory    ${LOG_SUITE_PATH}

    ${log_file_tmp}=    Join Path    ${LOG_SUITE_PATH}    ${SUITE NAME}
    ${SCREENSHOT_BASE}=    Set Variable    ${log_file_tmp}.IMG

    Set Global Variable    ${LOG_SUITE_PATH}
    Set Global Variable    ${SCREENSHOT_BASE}

Test-postCondition
    Log    Post-condition


Open Web
    Open Browser    ${URL}   chrome
    Log    Open web chrome

Close Web
    Close Browser


Go To Android Settings
    [Arguments]     ${ADB_SERIAL}=${DEVICE_SERIAL}
    Run    adb -s ${ADB_SERIAL} shell am start -a android.settings.SETTINGS


Increment And Format Call Count
    [Arguments]    ${call_count}
    ${call_count}=    Evaluate    ${call_count} + 1
    ${formatted_call_count}=    Evaluate    "{:03d}".format(${call_count})
    RETURN    ${call_count}    ${formatted_call_count}

FIND_IMAGE_AND_TOUCH_IT
    [Arguments]  ${find_img}  ${call_count}     ${Thresshold}=90

    ${call_count}    ${formatted_call_count}=    Increment And Format Call Count    ${call_count}

    ${SCREENSHOT_PATH_FILE}=    Set Variable    ${SCREENSHOT_BASE}${formatted_call_count}.png
    ${SCREENSHOT_PATH_FILE}=    Normalize Path    ${SCREENSHOT_PATH_FILE}

    ${EXPECTED_IMG_PATH_FILE}=    Join Path    ${WORKSPACE_PATH}    ${find_img}
    ${EXPECTED_IMG_PATH_FILE}=    Normalize Path    ${EXPECTED_IMG_PATH_FILE}

    # ADB screencap
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    screencap    -p    ${REMOTE_SCREENSHOT_PATH}
    Run Process    adb    -s    ${DEVICE_SERIAL}    pull    ${REMOTE_SCREENSHOT_PATH}    ${SCREENSHOT_PATH_FILE}
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    rm    -rf    ${REMOTE_SCREENSHOT_PATH}
    Sleep    1

    File Should Exist    ${SCREENSHOT_PATH_FILE}
    File Should Exist    ${EXPECTED_IMG_PATH_FILE}

    ${result}    ${X}    ${Y}=    ImageCompare.Find image on screen
    ...    ${SCREENSHOT_PATH_FILE}
    ...    ${EXPECTED_IMG_PATH_FILE}
    ...    threshold=${Thresshold}

    Run Keyword If    '${result}' == 'fail'
    ...    Run Keyword And Continue On Failure
    ...    Fail    ${find_img} detection fail.

    Run    adb -s ${DEVICE_SERIAL} shell input tap ${X} ${Y}
    Sleep    1

    RETURN    ${result}    ${call_count}

FIND_IMAGE
    [Arguments]  ${find_img}  ${call_count}     ${Thresshold}=90

    ${call_count}    ${formatted_call_count}=    Increment And Format Call Count    ${call_count}

    ${SCREENSHOT_PATH_FILE}=    Set Variable    ${SCREENSHOT_BASE}${formatted_call_count}.png
    ${SCREENSHOT_PATH_FILE}=    Normalize Path    ${SCREENSHOT_PATH_FILE}

    ${EXPECTED_IMG_PATH_FILE}=    Join Path    ${WORKSPACE_PATH}    ${find_img}
    ${EXPECTED_IMG_PATH_FILE}=    Normalize Path    ${EXPECTED_IMG_PATH_FILE}

    # ADB screencap
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    screencap    -p    ${REMOTE_SCREENSHOT_PATH}
    Run Process    adb    -s    ${DEVICE_SERIAL}    pull    ${REMOTE_SCREENSHOT_PATH}    ${SCREENSHOT_PATH_FILE}
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    rm    -rf    ${REMOTE_SCREENSHOT_PATH}
    Sleep    1

    File Should Exist    ${SCREENSHOT_PATH_FILE}
    File Should Exist    ${EXPECTED_IMG_PATH_FILE}

    ${result}    ${X}    ${Y}=    ImageCompare.Find image on screen
    ...    ${SCREENSHOT_PATH_FILE}
    ...    ${EXPECTED_IMG_PATH_FILE}
    ...    threshold=${Thresshold}

    Run Keyword If    '${result}' == 'fail'
    ...    Run Keyword And Continue On Failure
    ...    Fail    ${find_img} detection fail.

    RETURN   ${result}    ${call_count}

FIND_STRING_ON_SCREEN_AND_TOUCH_IT
    [Arguments]  ${text}  ${call_count}

    ${call_count}    ${formatted_call_count}=    Increment And Format Call Count    ${call_count}

    ${SCREENSHOT_PATH_FILE}=    Set Variable    ${SCREENSHOT_BASE}${formatted_call_count}.png
    ${SCREENSHOT_PATH_FILE}=    Normalize Path    ${SCREENSHOT_PATH_FILE}

    # ADB screencap
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    screencap    -p    ${REMOTE_SCREENSHOT_PATH}
    Run Process    adb    -s    ${DEVICE_SERIAL}    pull    ${REMOTE_SCREENSHOT_PATH}    ${SCREENSHOT_PATH_FILE}
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    rm    -rf    ${REMOTE_SCREENSHOT_PATH}
    Sleep    1

    File Should Exist    ${SCREENSHOT_PATH_FILE}

    ${result}    ${X}    ${Y}=    ImageCompare.Find string on screen
    ...    ${SCREENSHOT_PATH_FILE}
    ...    ${text}

    Run Keyword If    '${result}' == 'fail'
    ...    Run Keyword And Continue On Failure
    ...    Fail    Text '${text}' not found on screen.

    Run    adb -s ${DEVICE_SERIAL} shell input tap ${X} ${Y}
    Sleep    1

    RETURN    ${result}    ${call_count}
