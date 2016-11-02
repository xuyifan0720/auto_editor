# auto_editor
auto_editor.py includes prove of concept code.
Softimage Swift project is an independent program which uses same algorithm to process portrait.

You can build softimage.app by your own if you like.

OpenCV dependency is resolved in XCode build phase. You may have to add more script if more OpenCV library is required.

Known issue:
XCode will report error if you run after a successful build. Current script doesn't delete Framework folder if it exists. This issue is not a blocker.
