*** Settings ***
Library     SeleniumLibrary
Library     OperatingSystem
Library     Process
Library     String
Library     ../Plugin/Android.py
Library     ../Plugin/Helper.py     WITH NAME   UI
Library     ../Plugin/compare/ImageCompare.py


*** Variables ***
${URL}     https://www.youtube.com
#${URL}     https://www.google.com
${IMAGE}        F:\E\code\test\selenium-screenshot-1.png
${DEVICE_SERIAL}    ce11160baddc4c2c04
@{list}     ${1}    ${2}
@{log}      abc
...         xyz

${USER_AGENT}    user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0
@{OPTIONS}    ["--start-maximized","--disable-infobars","--disable-notifications","--disable-blink-features=AutomationControlled","--disable-gpu","--no-sandbox"]
${LOG_BASE_PATH}       ${CURDIR}/../LOG
${WORKSPACE_PATH}      tmp
${REMOTE_SCREENSHOT_PATH}    /sdcard/screenshot.png
${CALL_COUNT}   0
*** Keywords ***
Test-precondition
    [Documentation]     Tiền điều kiện để thực thi test
    Log    Pre-condition
    ${LOG_SUITE_PATH}    Set Variable    ${LOG_BASE_PATH}/${SUITE NAME}
    ${log_file_tmp}    Set Variable    ${LOG_SUITE_PATH}/${SUITE NAME}
    Set Global Variable    ${SCREENSHOT_BASE}    ${log_file_tmp}.IMG


Test-postCondition
    [Documentation]     Trả lại môi trường ban đầu để sẵn sàng cho test case mới
    Log    Post-condition

Open Web
    [Documentation]     Open 1 web với địa chỉ cụ thể trên trình duyệt example: open browser Chrome, truy cập tới trang google.com
    Open Browser    ${URL}   chrome
    Log    Open web chrome

Close Web
    [Documentation]     Đóng browser
    Close Browser

Search Keyword
    [Documentation]     Open web browser to research the object
    [Arguments]    ${keyword}
    Input Text    name=q    ${keyword}
    Press Keys    name=q    ENTER
    Wait Until Page Contains    ${keyword}
    Page Should Contain    text

Find Text on page
    [Documentation]     Sử dụng keyword page should contain trong thư viện selenium kiểm tra element "text" xuất hiện trên web đang mở
    [Arguments]     ${text}
    Page Should Contain     ${text}     loglevel=INFO

Go To Android Settings
    [Documentation]     Go to settings on android device
    [Arguments]     ${ADB_SERIAL}=${DEVICE_SERIAL}
    Run    adb -s ${ADB_SERIAL} shell am start -a android.settings.SETTINGS

Open Web2
    ${chrome options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
    FOR    ${arg}    IN    @{OPTIONS}
        Call Method    ${chrome options}    add_argument    ${arg}
    END
    Call Method    ${chrome options}    add_argument    ${USER_AGENT}
    Create Webdriver    Chrome    options=${chrome options}
    Go To    ${URL}

#---------Image Keyword---------------------#
Increment And Format Call Count
    [Arguments]    ${call_count}
    ${call_count}=    Set Variable    ${call_count} + 1
    ${formatted_call_count}=    Evaluate    "{:03d}".format(${call_count})
    RETURN    ${call_count}    ${formatted_call_count}



FIND_IMAGE_AND_TOUCH_IT
    [Arguments]  ${find_img}  ${call_count}     ${Thresshold}=90

   # Include Increment And Format Call Count in all image-related keywords!!!
    ${call_count}    ${formatted_call_count}=    Increment And Format Call Count    ${call_count}
    ${SCREENSHOT_PATH_FILE}    Set Variable    ${SCREENSHOT_BASE}${formatted_call_count}.png
    ${EXPECTED_IMG_PATH_FILE}    Set Variable    ${WORKSPACE_PATH}${find_img}

    # ADB SCREENCAP
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    screencap    -p    ${REMOTE_SCREENSHOT_PATH}
    Run Process    adb    -s    ${DEVICE_SERIAL}    pull    ${REMOTE_SCREENSHOT_PATH}    ${SCREENSHOT_PATH_FILE}
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    rm    -rf    ${REMOTE_SCREENSHOT_PATH}
    SLEEP    1

    # Image Compare
    ${result}    ${X}    ${Y}  ${percent}=    ImageCompare.Find image on screen    ${SCREENSHOT_PATH_FILE}    ${EXPECTED_IMG_PATH_FILE}   threshold=${Thresshold}
    ${percent_int}=  Convert To Integer  ${percent}
        IF  ${percent_int} < 97
        Log  ${find_img} compare persent low than 97%. match percent is ${percent}%. please, check image!!  WARN
    END
    Run Keyword if    '${result}' == 'fail'    Run Keyword And Continue On Failure    Fail    ${find_img} detection fail.

    Android.Touch  ${X}   ${Y}
    SLEEP    1

    RETURN    ${result}    ${call_count}

FIND_IMAGE
    [Arguments]  ${find_img}  ${call_count}     ${Thresshold}=90

   # Include Increment And Format Call Count in all image-related keywords!!!
    ${call_count}    ${formatted_call_count}=    Increment And Format Call Count    ${call_count}
    ${SCREENSHOT_PATH_FILE}    Set Variable    ${SCREENSHOT_BASE}${formatted_call_count}.png
    ${EXPECTED_IMG_PATH_FILE}    Set Variable    ${WORKSPACE_PATH}${find_img}

    # ADB SCREENCAP
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    screencap    -p    ${REMOTE_SCREENSHOT_PATH}
    Run Process    adb    -s    ${DEVICE_SERIAL}    pull    ${REMOTE_SCREENSHOT_PATH}    ${SCREENSHOT_PATH_FILE}
    Run Process    adb    -s    ${DEVICE_SERIAL}    shell    rm    -rf    ${REMOTE_SCREENSHOT_PATH}
    SLEEP    1

    # Image Compare
    ${result}    ${X}    ${Y}  ${percent}=    ImageCompare.Find image on screen    ${SCREENSHOT_PATH_FILE}    ${EXPECTED_IMG_PATH_FILE}   threshold=${Thresshold}
    ${percent_int}=  Convert To Integer  ${percent}
        IF  ${percent_int} < 97
        Log  ${find_img} compare persent low than 97%. match percent is ${percent}%. please, check image!!  WARN
        END
    Run Keyword if    '${result}' == 'fail'    Run Keyword And Continue On Failure    Fail    ${find_img} detection fail.

    RETURN   ${result}    ${call_count}
