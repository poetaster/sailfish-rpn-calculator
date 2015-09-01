/****************************************************************************************
**
** Copyright (C) 2013 Riccardo Ferrazzo <f.riccardo87@gmail.com>.
** All rights reserved.
**
** This program is based on ubuntu-calculator-app created by:
** Dalius Dobravolskas <dalius@sandbox.lt>
** Riccardo Ferrazzo <f.riccardo87@gmail.com>
**
** This file is part of ScientificCalc Calculator.
** ScientificCalc Calculator is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** ScientificCalc Calculator is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.3
import "../elements"
//import QtFeedback 5.0

Page {
    id: page

    property string currentOperand: ''
    property bool currentOperandValid: true
    property var currentStack: []

    property bool engineLoaded: false

    /*
    HapticsEffect {
        id: vibration
        intensity: 0.8
        duration: 50
    }

    HapticsEffect {
        id: longVibration
        intensity: 0.8
        duration: 200
    }
    */

    Popup {
        id: popup
        z: 10

        timeout: 3000
    }

    Connections {
        target: settings
        onAngleUnitChanged: {
            python.changeTrigonometricUnit(settings.angleUnit);
        }
        onReprFloatPrecisionChanged: {
            python.changeReprFloatPrecision(settings.reprFloatPrecision);
        }
        onAutoSimplifyChanged: {
            python.enableAutoSimplify(settings.autoSimplify);
        }
        onSymbolicModeChanged: {
            python.enableSymbolicMode(settings.symbolicMode);
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../python'));

            setHandler('currentOperand', currentOperandHandler);
            setHandler('newStack', newStackHandler);
            setHandler('NotEnoughOperandsException', notEnoughOperandsExceptionHandler);
            setHandler('WrongOperandsException', wrongOperandsExceptionHandler);
            setHandler('ExpressionNotValidException', expressionNotValidExceptionHandler);
            setHandler('BackendException', backendExceptionHandler);
            setHandler('EngineLoaded', engineLoadedHandler);
            setHandler('symbolsPush', symbolsPushHandler);


            importModule('rpncalc_engine', function () {
                console.log("Module successfully imported. Loading engine.");
                changeTrigonometricUnit(settings.angleUnit);
                changeReprFloatPrecision(settings.reprFloatPrecision);
                newStackHandler([]);

                pageStack.pushAttached(Qt.resolvedUrl("Settings.qml"));
            });
        }

        function engineLoadedHandler(){
            popup.notify("Symbolic engine loaded");
            page.engineLoaded = true;

            changeTrigonometricUnit(settings.angleUnit);
            changeReprFloatPrecision(settings.reprFloatPrecision);
            enableSymbolicMode(settings.symbolicMode);
            enableAutoSimplify(settings.autoSimplify);
        }

        function expressionNotValidExceptionHandler(){
            popup.notify("Expression not valid.");
        }

        function backendExceptionHandler(){
            popup.notify("Error.");
        }

        function notEnoughOperandsExceptionHandler(nbExpected, nbAvailabled){
            popup.notify("Not enough operands. Expecting " + nbExpected + ".");
        }

        function wrongOperandsExceptionHandler(expectedOperands, nb){
            if(nb > 0){
                popup.notify("Wrongs operands. Expected " + nb + " " + operandTypeToString(expectedOperands) + ".");
            }else{
                popup.notify("Wrongs operands. Expected " + operandTypeToString(expectedOperands) + ".");
            }
        }

        function enableSymbolicMode(enabled){
            call("rpncalc_engine.engine.setSymbolicMode", [enabled], function (){});
        }

        function enableAutoSimplify(enabled){
            call("rpncalc_engine.engine.setAutoSimplify", [enabled], function (){});
        }

        function changeTrigonometricUnit(unit){
            call("rpncalc_engine.engine.changeTrigonometricUnit", [unit], function (){});
        }

        function changeReprFloatPrecision(prec){
            call("rpncalc_engine.engine.setBeautifierPrecision", [prec], function (){});
        }

        function operandTypeToString(operands){
            var i = 0;
            var rstr = "";
            for(i=0; i< operands.length; i++){
                switch(Number(operands[i])){
                    case 1:
                        rstr += "Integer,";
                        break;
                    case 2:
                        rstr += "Float,";
                        break;
                }
            }
            rstr = rstr.substring(0, rstr.length-1);

            if(operands.length > 1){
                rstr = "(" + rstr + ")";
            }
            return rstr;
        }


        function currentOperandHandler(operand, valid){
            page.currentOperand = operand;
            page.currentOperandValid = valid;
        }

        function newStackHandler(stack){
            memory.clear();
            var i=0;
            for(i=stack.length-1; i>=0 ; i--){
                memory.append({isLastItem: i == stack.length ? true : false, value: stack[i]["expr"]})
                calcScreen.view.positionViewAtEnd();
            }

            //fill in first 10 of stack
            for(i=memory.count; i<1 ; i++){
                memory.insert(0, {isLastItem: i == stack.length ? true : false, value: ""});
                calcScreen.view.positionViewAtEnd();
            }

            page.currentStack = stack;
        }


        function processInput(input, type){
            call("rpncalc_engine.engine.processInput", [input, type], function (){});
        }

        function clearCurrentOperand(){
            call("rpncalc_engine.engine.clearCurrentOperand", function(){});
        }

        function delLastOperandCharacter(){
            call("rpncalc_engine.engine.delLastOperandCharacter", function(){});
        }

        function dropFirstStackOperand(){
            call("rpncalc_engine.engine.stackDropFirst", function(){});
        }

        function dropAllStackOperand(){
            call("rpncalc_engine.engine.stackDropAll", function(){});
        }

        function dropStackOperand(idx){
            call("rpncalc_engine.engine.stackDrop", [idx], function(){});
        }

        function pickStackOperand(idx){
            call("rpncalc_engine.engine.stackPick", [idx], function(){});
        }

        function symbolsPushHandler(pageName, symbols){
            pageStack.push(Qt.resolvedUrl("SymbolPage.qml"), {"mainPage": page, "pageName": pageName, "symbols": symbols});
        }
    }

    function formulaPush(visual, engine, type) {
        python.processInput(engine, type);
    }

    function stackDropFirst(){
        python.dropFirstStackOperand();
    }

    function stackDropAll(){
        python.dropAllStackOperand();
    }

    function stackDropUIIndex(idx){
        var engineIdx = idx - 1;
        python.dropStackOperand(engineIdx);
    }

    function stackPickUIIndex(idx){
        var engineIdx = idx - 1;
        python.pickStackOperand(engineIdx);
    }

    function formulaPop() {
        python.delLastOperandCharacter(); // might need an UNDO type of thing if last typed key != 1 character
    }

    function formulaReset() {
        python.clearCurrentOperand();
    }

    function resetKeyboard() {
        kbd.action = 0;
    }

    function formatNumber(n, maxsize){
        var str = String(n);
        var l = str.length;
        var round_n;

        if(l > maxsize){

            if(str.split('e').length > 1){
                round_n = Number(n).toPrecision(maxsize-5);
            }else{
                round_n = Number(n).toPrecision(maxsize);
                if(String(round_n).length > maxsize){
                    round_n = Number(n).toExponential(maxsize-4);
                }
            }

            str = String(round_n);
        }

        return str;
    }

    function copyToClipboard(value){
        Clipboard.text = value;
    }

    Item {
        id: heightMeasurement
        anchors.bottom: currentOperandEditor.top
        anchors.top: parent.top

        visible: false
    }

    CalcScreen {
        id: calcScreen

        anchors.bottom: currentOperandEditor.top
        anchors.left: parent.left
        anchors.right: parent.right

        // Don't why I need 10 here... without it GlassItem is displayed too low
        height: heightMeasurement.height + 10 > contentHeight ? contentHeight : heightMeasurement.height + 10

        clip: true

        model: Memory {
            id: memory
            stack: currentStack
        }
    }

    OperandEditor {
        id: currentOperandEditor

        anchors.bottom: infosRow.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.leftMargin: 10

        operand: currentOperand
        operandInvalid: currentOperandValid ? false : true  // <= lol

        backButton.onClicked: {
            formulaPop();
            /*
            if(settings.vibration()){
                vibration.start();
            }
            */
        }

        backButton.onPressAndHold: {
            formulaReset();
            /*
            if(settings.vibration()){
                vibration.start();
            }
            */
        }
    }

    Row {
        id: infosRow

        anchors.bottom: kbd.top
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottomMargin: 10

        spacing: 15

        Label {
            id: mode

            text: !engineLoaded ? "Degraded" : settings.symbolicMode ? "Symbolic" : "Numeric"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeExtraSmall
            //font.bold: !engineLoaded

            color: !engineLoaded ? "red" : Theme.secondaryColor
        }


        Label {
            id: unit

            text: settings.angleUnit
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeExtraSmall

            color: Theme.secondaryColor
        }

    }

    StdKeyboard {
        id: kbd
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20

        width: parent.width
    }
}


