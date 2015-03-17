import QtQuick 2.0
import QtQuick.Controls 1.0;
import QtQuick.Layouts 1.0;
import QtQuick.Dialogs 1.0;
import QtQuick.Window 2.1;
import QtQuick.Controls.Styles 1.1
import Ethereum 1.0

import "../ext/filter.js" as Eth
import "../ext/http.js" as Http


ApplicationWindow {
    id: root
    
    flags: Qt.FramelessWindowHint
    //flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint
    // Use this to make the window frameless. But then you'll need to do move and resize by hand
    color: "transparent"

    property var ethx : Eth.ethx
    property var catalog;

    width: 1200
    height: 820
    minimumHeight: 600
    minimumWidth: 800
    x: 50 
    y: 50 

    // You can use (Screen.desktopAvailableHeight - height)/2 but that would keep

    title: "Mist"

    TextField {
        id: copyElementHax
        visible: false
    }

    function copyToClipboard(text) {
        copyElementHax.text = text
        copyElementHax.selectAll()
        copyElementHax.copy()
    }

    // Takes care of loading all default plugins
    Component.onCompleted: {

        catalog = addPlugin("./views/catalog.qml", {noAdd: true, close: false, section: "begin", active: true});

        var walletWeb = addPlugin("./views/browser.qml", {noAdd: true, close: false, section: "ethereum", active: false});
        walletWeb.view.url = "http://ethereum-dapp-wallet.meteor.com/";
        walletWeb.menuItem.title = "Wallet";

        addPlugin("./views/miner.qml", {noAdd: true, close: false, section: "legacy", active: false});
        addPlugin("./views/network.qml", {noAdd: true, close: false, section: "ethereum", active: false});

       /* var whisperTab = addPlugin("./views/browser.qml", {noAdd: true, close: true, section: "ethereum", active: false});
        whisperTab.view.url = "http://ethereum-dapp-whisper-client.meteor.com/";
        whisperTab.menuItem.title = "Whisper Chat";
*/
        addPlugin("./views/wallet.qml", {noAdd: true, close: false, section: "legacy"});        
        addPlugin("./views/transaction.qml", {noAdd: true, close: false, section: "legacy"});
        addPlugin("./views/whisper.qml", {noAdd: true, close: false, section: "legacy"});
        addPlugin("./views/chain.qml", {noAdd: true, close: false, section: "legacy"});
        addPlugin("./views/pending_tx.qml", {noAdd: true, close: false, section: "legacy"});
        addPlugin("./views/info.qml", {noAdd: true, close: false, section: "legacy"});

        mainSplit.setView(catalog.view, catalog.menuItem);

        //newBrowserTab("http://ethereum-dapp-catalog.meteor.com");

        // Command setup
        gui.sendCommand(0)
    }

    function activeView(view, menuItem) {
        mainSplit.setView(view, menuItem)
        /*if (view.hideUrl) {
            urlPane.visible = false;
            mainView.anchors.top = rootView.top
        } else {
            urlPane.visible = true;
            mainView.anchors.top = divider.bottom
        }*/

    }

    function addViews(view, path, options) {
        var views = mainSplit.addComponent(view, options)
        views.menuItem.path = path

        mainSplit.views.push(views);

        if(!options.noAdd) {
            gui.addPlugin(path)
        }

        return views
    }

    function addPlugin(path, options) {
        try {
            if(typeof(path) === "string" && /^https?/.test(path)) {
                console.log('load http')
                Http.request(path, function(o) {
                    if(o.status === 200) {
                        var view = Qt.createQmlObject(o.responseText, mainView, path)
                        addViews(view, path, options)
                    }
                })

                return
            }

            var component = Qt.createComponent(path);
            if(component.status != Component.Ready) {
                if(component.status == Component.Error) {
                    ethx.note("error: ", component.errorString());
                }

                return
            }

            var view = mainView.createView(component, options)
            var views = addViews(view, path, options)

            return views
        } catch(e) {
            console.log(e)
        }
    }

    function newBrowserTab(url) {
        
        var urlMatches = url.toString().match(/^[a-z]*\:\/\/([^\/?#]+)(?:[\/?#]|$)/i);
        var requestedDomain = urlMatches && urlMatches[1];

        var domainAlreadyOpen = false;

        for(var i = 0; i < mainSplit.views.length; i++) {
            if (mainSplit.views[i].view.url) {
                var matches = mainSplit.views[i].view.url.toString().match(/^[a-z]*\:\/\/(?:www\.)?([^\/?#]+)(?:[\/?#]|$)/i);
                var existingDomain = matches && matches[1];
                if (requestedDomain == existingDomain) {
                    domainAlreadyOpen = true;
                    
                    if (mainSplit.views[i].view.url != url){
                        mainSplit.views[i].view.url = url;
                    }
                    
                    activeView(mainSplit.views[i].view, mainSplit.views[i].menuItem);
                }
            }
        }  

        if (!domainAlreadyOpen) {            
            var window = addPlugin("./views/browser.qml", {noAdd: true, close: true, section: "apps", active: true});
            window.view.url = url;
            window.menuItem.title = "Mist";
            activeView(window.view, window.menuItem);
        }
    }



    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem {
                text: "New tab"
                shortcut: "Ctrl+t"
                onTriggered: {
	            activeView(catalog.view, catalog.menuItem);
                }
            }

            MenuSeparator {}

            MenuItem {
                text: "Import key"
                shortcut: "Ctrl+i"
                onTriggered: {
                    generalFileDialog.show(true, function(path) {
                        gui.importKey(path)
                    })
                }
            }

            MenuItem {
                text: "Export keys"
                shortcut: "Ctrl+e"
                onTriggered: {
                    generalFileDialog.show(false, function(path) {
                    })
                }
            }

            MenuItem {
                text: "Generate key"
                shortcut: "Ctrl+k"
                onTriggered: gui.generateKey()
            }
        }

        Menu {
            title: "Developer"
            MenuItem {
                text: "Import Tx"
                onTriggered: {
                    txImportDialog.visible = true
                }
            }

            MenuItem {
                text: "Run JS file"
                onTriggered: {
                    generalFileDialog.show(true, function(path) {
                        eth.evalJavascriptFile(path)
                    })
                }
            }

            MenuItem {
                text: "Dump state"
                onTriggered: {
                    generalFileDialog.show(false, function(path) {
                        // Empty hash for latest
                        gui.dumpState("", path)
                    })
                }
            }

            MenuSeparator {}
        }

        Menu {
            title: "Network"
            MenuItem {
                text: "Add Peer"
                shortcut: "Ctrl+p"
                onTriggered: {
                    addPeerWin.visible = true
                }
            }
            MenuItem {
                text: "Show Peers"
                shortcut: "Ctrl+e"
                onTriggered: {
                    peerWindow.visible = true
                }
            }
        }

        Menu {
            title: "Help"
            MenuItem {
                text: "About"
                onTriggered: {
                    aboutWin.visible = true
                }
            }
        }

    }

    property var blockModel: ListModel {
        id: blockModel
    }

    

            

    Rectangle {
        id: windowChrome
        color: "#EBE8E8"
        anchors.fill: parent
        radius: 3


        




        /************************/
        /*                      */
        /*  Resizeable Borders  */
        /*                      */
        /************************/

        MouseArea { 
            id: rightResizableBar
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: 5
            cursorShape: Qt.SizeHorCursor; 

            property real lastMouseX: 0
            onPressed: {
                lastMouseX = mouseX
            }
            onPositionChanged: {
                if (!(root.width + mouseX - lastMouseX < root.minimumWidth)) {
                     root.width += (mouseX - lastMouseX)
                }
            }
        }        

        MouseArea { 
            id: leftResizableBar
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            width: 5
            cursorShape: Qt.SizeHorCursor; 

            property real lastMouseX: 0
            property real lastRight: root.x + root.width
            onPressed: {
                lastMouseX = mouseX
                lastRight = root.x + root.width
            }
            onPositionChanged: {            
                if (!(root.width - mouseX + lastMouseX < root.minimumWidth)) {
                    root.width -= (mouseX - lastMouseX)
                    root.x = lastRight - root.width
                }
            }
        }

        MouseArea { 
            id: bottomResizableBar
            anchors {
                bottom: parent.bottom
                right: parent.right
                left: parent.left
            }
            height: 5
            cursorShape: Qt.SizeVerCursor; 

            property real lastMouseY: 0
            onPressed: {
                lastMouseY = mouseY
            }
            onPositionChanged: {
                if (!(root.height + mouseY - lastMouseY < root.minimumHeight)) {
                     root.height += (mouseY - lastMouseY)
                }
            }
        }        

        MouseArea { 
            id: bottomRightResizableHandle
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
            width: 5
            height: 5
            cursorShape: Qt.SizeFDiagCursor; 

            property real lastMouseX: 0
            property real lastMouseY: 0
            onPressed: {
                lastMouseX = mouseX
                lastMouseY = mouseY
            }
            onPositionChanged: {
                if (!(root.width + mouseX - lastMouseX < root.minimumWidth)) {
                     root.width += (mouseX - lastMouseX)
                }

                if (!(root.height + mouseY - lastMouseY < root.minimumHeight)) {
                     root.height += (mouseY - lastMouseY)
                }
            }
        } 
    }

    Rectangle {
        id: topBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 18.4
        z: 100
        color: "transparent"

        MouseArea {
            id: menuMouseArea
            anchors.fill: parent
            property real lastMouseX: 0
            property real lastMouseY: 0
            hoverEnabled: true
            onPressed: {
                lastMouseX = mouseX
                lastMouseY = mouseY
            }
            onPositionChanged: {
                if (menuMouseArea.pressed){
                    root.x += (mouseX - lastMouseX)
                    root.y += (mouseY - lastMouseY)    
                }
                
            }
            onEntered: {
                topBar.state = "hovered"
            }
            onExited: {
                topBar.state = "normal"
            }
        }

        // gradient: Gradient {
        //      GradientStop { position: 0.0; color: "#FFFFFFFF" }
        //      GradientStop { position: 1.0; color: "#00FFFFFF" }
        // }

 

        Rectangle {
            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                left: parent.left
                leftMargin: 194
            }
            radius: 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FFFFFFFF" }
                GradientStop { position: 1.0; color: "#00FFFFFF" }
            }
        }

        Rectangle {
            id: topbarBackground
            anchors.fill: parent
            opacity: 0.0
            radius: 3
            color: "#AAA0A0"
        }
        

        states: [
        State {
            name: "normal"
            when: menuMouseArea.hovered
            PropertyChanges { 
                target: topbarBackground
                opacity: 0
            }
        },
        State {
            name: "hovered"
            when: menuMouseArea.hovered
            PropertyChanges { 
                target: topbarBackground
                opacity: 1
            }
        }]


        transitions: Transition {
            NumberAnimation { 
                properties: "opacity"
                duration: 250
                easing.type: Easing.InOutQuad 
            }
        }

        /************************/
        /*   Semafor Buttons    */
        /************************/

         Rectangle {
            id: semaforButtons
            color: "transparent"
            height: 32
            
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Rectangle {
                    color: 'transparent'
                    width: 13
                    height: 20
                    x: 3
                    
                    Image {
                         height: 13
                         width: 13
                         source: toolbarCloseButton.containsMouse ?  "../window-control/window-close.png" :  "../window-control/window-close-hover.png"
                         anchors.centerIn: parent
                         
                         MouseArea {
                            id: toolbarCloseButton
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Qt.quit() //gui.stop();

                            onEntered: {
                                topBar.state = "hovered"
                            }
                        }
                     }  
                }
                Rectangle {
                    color: 'transparent'
                    width: 13
                    height: 20
                    x: 21
                    
                    Image {
                         height: 13
                         width: 13
                         source: toolbarminimizeButton.containsMouse ?  "../window-control/window-minimize.png" :  "../window-control/window-minimize-hover.png"
                         anchors.centerIn: parent
                         
                         MouseArea {
                            id: toolbarminimizeButton
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Minimize");
                                // Neither works..
                                //root.visibility = QWindow.minimized;
                                // root.showMinimized();
                            }
                            onEntered: {
                                topBar.state = "hovered"
                                console.log(topBar.state )
                            }
                        }
                     }  
                }

                Rectangle {
                    color: 'transparent'
                    width: 13
                    height: 20
                    x: 40

                    Image {
                         height: 13
                         width: 13
                         source: toolbarzoomButton.containsMouse ?  "../window-control/window-zoom.png" :  "../window-control/window-zoom-hover.png"
                         anchors.centerIn: parent
                         
                         MouseArea {
                            id: toolbarzoomButton
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Maximize");
                                // Neither works..
                                //root.visibility = QWindow.maximized;
                                //root.showMaximized();
                            } 
                            onEntered: {
                                topBar.state = "hovered"
                            }                           
                        }
                    }  
            }
        }
    }


    SplitView {
        property var views: [];

        id: mainSplit
        anchors.fill: windowChrome
        anchors.margins: 2
        z: 50
        //color: "brown"
        //radius: 5

        //resizing: false  // this is NOT where we remove that damning resizing handle..
        handleDelegate: Item {
            //This handle is a way to remove the line between the split views
            Rectangle {
                anchors.fill: parent
            }
         }

        function setView(view, menu) {
            for(var i = 0; i < views.length; i++) {
                views[i].view.visible = false
                views[i].menuItem.setSelection(false)
            }
            view.visible = true
            menu.setSelection(true)
        }

        function addComponent(view, options) {
            view.visible = false
            view.anchors.fill = mainView

            var menuItem = menu.createMenuItem(view, options);
            if( view.hasOwnProperty("menuItem") ) {
                view.menuItem = menuItem;
            }

            if( view.hasOwnProperty("onReady") ) {
                view.onReady.call(view)
            }

            if( options.active ) {
                setView(view, menuItem)
            }


            return {view: view, menuItem: menuItem}
        }



        /*********************
         * Main menu.
         ********************/
         Rectangle {
             id: menu
             Layout.minimumWidth: 192
             Layout.maximumWidth: 192
             anchors.top: parent.top

            FontLoader { 
               id: sourceSansPro
               source: "fonts/SourceSansPro-Regular.ttf" 
            }
            FontLoader { 
               source: "fonts/SourceSansPro-Semibold.ttf" 
            }            
            FontLoader { 
               source: "fonts/SourceSansPro-Bold.ttf" 
            } 
            FontLoader { 
               source: "fonts/SourceSansPro-Black.ttf" 
            }            
            FontLoader { 
               source: "fonts/SourceSansPro-Light.ttf" 
            }              
            FontLoader { 
               source: "fonts/SourceSansPro-ExtraLight.ttf" 
            }  
            FontLoader { 
               id: simpleLineIcons
               source: "fonts/Simple-Line-Icons.ttf" 
            }

            Rectangle {
                id: sideMenuInteractions
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    property real lastMouseX: 0
                    property real lastMouseY: 0
                    onPressed: {
                        lastMouseX = mouseX
                        lastMouseY = mouseY
                    }
                    onPositionChanged: {
                        root.x += (mouseX - lastMouseX)
                        root.y += (mouseY - lastMouseY)
                    }
                }
            }

             Rectangle {
                     width: parent.height
                     height: parent.width
                     anchors.centerIn: parent
                     rotation: 90

                     gradient: Gradient {
                         GradientStop { position: 0.0; color: "#E2DEDE" }
                         GradientStop { position: 0.1; color: "#EBE8E8" }
                         GradientStop { position: 1.0; color: "#EBE8E8" }
                     }
             }

             Component {
                 id: menuItemTemplate
                 Rectangle {
                     id: menuItem
                     property var view;
                     property var path;
                     property var closable;
                     property var badgeContent;

                     property alias title: label.text
                     property alias icon: icon.source
                     property alias secondaryTitle: secondary.text
                     property alias badgeNumber: badgeNumberLabel.text
                     property alias badgeIcon: badgeIconLabel.text

                     function setSelection(on) {
                         sel.visible = on
                         
                         if (this.closable == true) {
                                closeIcon.visible = on
                         }
                     }

                     function setAsBigButton(on) {
                        newAppButton.visible = on
                        label.visible = !on
                        buttonLabel.visible = on
                     }
 
                     width: 192
                     height: 55
                     color: "#00000000"

                     anchors {
                         left: parent.left
                         leftMargin: 4
                     }

                     Rectangle {
                         // New App Button
                         id: newAppButton
                         visible: false 
                         anchors.fill: parent
                         anchors.rightMargin: 8
                         border.width: 0
                         radius: 5
                         height: 55
                         width: 180
                         color: "#F3F1F3"
                     }

                     Rectangle {
                         id: sel
                         visible: false
                         anchors.fill: parent
                         color: "#00000000"
                         Rectangle {
                             id: r
                             anchors.fill: parent
                             border.width: 0
                             radius: 5
                             color: "#FAFAFA"
                         }
                         Rectangle {
                             anchors {
                                 top: r.top
                                 bottom: r.bottom
                                 right: r.right
                             }
                             width: 10
                             color: "#FAFAFA"
                             border.width:0

                             Rectangle {
                                // Small line on top of selection. What's this for?
                                 anchors {
                                     left: parent.left
                                     right: parent.right
                                     top: parent.top
                                 }
                                 height: 1
                                 color: "#FAFAFA"
                             }

                             Rectangle {
                                // Small line on bottom of selection. What's this for again?
                                 anchors {
                                     left: parent.left
                                     right: parent.right
                                     bottom: parent.bottom
                                 }
                                 height: 1
                                 color: "#FAFAFA"
                             }
                         }
                     }

                     MouseArea {
                         anchors.fill: parent
                         hoverEnabled: true
                         onClicked: {
                             activeView(view, menuItem);
                         }
                         onEntered: {
                            if (parent.closable == true) {
                                closeIcon.visible = sel.visible
                            }
                         }
                         onExited:  {
                            closeIcon.visible = false
                         }
                     }

                     Image {
                         id: icon
                         height: 28
                         width: 28
                         anchors {
                             left: parent.left
                             verticalCenter: parent.verticalCenter
                             leftMargin: 6
                         }
                     }

                     Text {
                        id: buttonLabel
                        visible: false
                        text: "GO TO NEW APP"
                        font.family: sourceSansPro.name 
                        font.weight: Font.DemiBold
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#AAA0A0"
                     }   

                    Text {
                         id: label
                         font.family: sourceSansPro.name 
                         font.weight: Font.DemiBold
                         elide: Text.ElideRight
                         x:250
                         color: "#665F5F"
                         font.pixelSize: 14
                         anchors {
                             left: icon.right
                             right: parent.right
                             verticalCenter: parent.verticalCenter
                             leftMargin: 6
                             rightMargin: 8
                             verticalCenterOffset: (secondaryTitle == "") ? 0 : -10;
                         }


                         
                         
                     }

                     Text {
                         id: secondary
                         //only shows secondary title if there's no badge
                         visible: (badgeContent == "icon" || badgeContent == "number" )? false : true
                         font.family: sourceSansPro.name 
                         font.weight: Font.Light
                         anchors {
                             left: icon.right
                             leftMargin: 6
                             top: label.bottom
                         }
                         color: "#6691C2"
                         font.pixelSize: 12
                     }

                     Rectangle {
                        id: closeIcon
                        visible: false
                        width: 10
                        height: 10
                        color: "#FAFAFA"
                        anchors {
                            fill: icon
                        }

                        MouseArea {
                             anchors.fill: parent
                             onClicked: {
                                 menuItem.closeApp()
                             }
                         }

                        Text {
                             
                             font.family: simpleLineIcons.name 
                             anchors {
                                 centerIn: parent
                             }
                             color: "#665F5F"
                             font.pixelSize: 20
                             text: "\ue082"
                         }
                     }                     

                     Rectangle {
                        id: badge
                        visible: (badgeContent == "icon" || badgeContent == "number" )? true : false 
                        width: 32
                        color: "#05000000"
                        anchors {
                            right: parent.right;
                            top: parent.top;
                            bottom: parent.bottom;
                            rightMargin: 4;
                        }
                                      
                        Text {
                             id: badgeIconLabel
                             visible: (badgeContent == "icon") ? true : false;
                             font.family: simpleLineIcons.name 
                             anchors {
                                 centerIn: parent
                             }
                             horizontalAlignment: Text.AlignCenter
                             color: "#AAA0A0"
                             font.pixelSize: 20
                             text: badgeIcon
                         }                       

                        Text {
                             id: badgeNumberLabel
                             visible: (badgeContent == "number") ? true : false;
                             anchors {
                                 centerIn: parent
                             }
                             horizontalAlignment: Text.AlignCenter
                             font.family: sourceSansPro.name 
                             font.weight: Font.Light
                             color: "#AAA0A0"
                             font.pixelSize: 18
                             text: badgeNumber
                         }
                     }
                     


                     function closeApp() {
                         if(!this.closable) { return; }

                         if(this.view.hasOwnProperty("onDestroy")) {
                             this.view.onDestroy.call(this.view)
                         }

                         this.view.destroy()
                         this.destroy()
                         for (var i = 0; i < mainSplit.views.length; i++) {
                             var view = mainSplit.views[i];
                             if (view.menuItem === this) {
                                 mainSplit.views.splice(i, 1);
                                 break;
                             }
                         }
                         gui.removePlugin(this.path)
                         activeView(mainSplit.views[0].view, mainSplit.views[0].menuItem);
                     }
                 }
             }

             function createMenuItem(view, options) {
                 if(options === undefined) {
                     options = {};
                 }

                 var section;
                 switch(options.section) {
                     case "begin":
                     section = menuBegin
                     break;
                     case "ethereum":
                     section = menuDefault;
                     break;
                     case "legacy":
                     section = menuLegacy;
                     break;
                     default:
                     section = menuApps;
                     break;
                 }

                 var comp = menuItemTemplate.createObject(section)
                 comp.view = view
                 comp.title = view.title

                 if(view.hasOwnProperty("iconSource")) {
                     comp.icon = view.iconSource;
                 }
                 comp.closable = options.close;

                 if (options.section === "begin") {
                    comp.setAsBigButton(true)
                 }

                 return comp
             }


             ColumnLayout {
                id: menuColumn
                y: 10
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 3
                
                Rectangle {
                    height: 18.4
                }

                ColumnLayout {
                     id: menuBegin
                     spacing: 3
                     anchors {
                         left: parent.left
                         right: parent.right
                     }
                 }

                 Rectangle {
                     height: 19
                     color: "transparent"
                     Text {
                         text: "ETHEREUM"
                         font.family: sourceSansPro.name 
                         font.weight: Font.Regular
                         // anchors.top:  20
                         // anchors.left:  16
                        anchors {
                            leftMargin: 12
                            topMargin: 4
                            fill: parent
                        }
                         // anchors.leftMargin: 16 
                         // anchors.topMargin: 16 
                        // anchors.verticalCenterOffset: 50
                         color: "#AAA0A0" 
                     }
                 }


                 ColumnLayout {
                     id: menuDefault
                     spacing: 3
                     anchors {
                         left: parent.left
                         right: parent.right
                     }
                 }

                 Rectangle {
                     height: 19
                     color: "#00ff00"
                     visible: (menuApps.children.length > 0)

                     Text {
                         text: "APPS"
                         font.family: sourceSansPro.name 
                         font.weight: Font.Regular
                         anchors.fill: parent
                         anchors.leftMargin: 16
                         color: "#AAA0A0"
                     }
                 }

                 ColumnLayout {
                     id: menuApps
                     spacing: 3


                     anchors {
                         left: parent.left
                         right: parent.right
                     }
                 }

                 ColumnLayout {
                     id: menuLegacy
                     visible: true
                     spacing: 3
                     anchors {
                         left: parent.left
                         right: parent.right
                     }
                 }
             }
         }

         /*********************
          * Main view
          ********************/
          Rectangle {
              id: rootView
              anchors.right: parent.right
              anchors.left: menu.right
              anchors.bottom: parent.bottom
              anchors.top: parent.top
              color: "#00000000"             

              Rectangle {
                  id: mainView
                  color: "#00000000"
                  anchors.right: parent.right
                  anchors.left: parent.left
                  anchors.bottom: parent.bottom
                  anchors.top: parent.top

                  function createView(component) {
                      var view = component.createObject(mainView)

                      return view;
                  }
            }
        }
      }


      /******************
       * Dialogs
       *****************/
       FileDialog {
           id: generalFileDialog
           property var callback;
           onAccepted: {
               var path = this.fileUrl.toString();
               callback.call(this, path);
           }

           function show(selectExisting, callback) {
               generalFileDialog.callback = callback;
               generalFileDialog.selectExisting = selectExisting;

               this.open();
           }
       }


       /******************
        * Wallet functions
        *****************/
        function importApp(path) {
            var ext = path.split('.').pop()
            if(ext == "html" || ext == "htm") {
                eth.openHtml(path)
            }else if(ext == "qml"){
                addPlugin(path, {close: true, section: "apps"})
            }
        }

        function setWalletValue(value) {
            //walletValueLabel.text = value
        }

        function loadPlugin(name) {
            console.log("Loading plugin" + name)
            var view = mainView.addPlugin(name)
        }

        function clearPeers() { peerModel.clear() }
        function addPeer(peer) { peerModel.append(peer) }

        function setPeerCounters(text) {
            //peerCounterLabel.text = text
        }

        function timeAgo(unixTs){
            var lapsed = (Date.now() - new Date(unixTs*1000)) / 1000
            return  (lapsed + " seconds ago")
        }

        function convertToPretty(unixTs){
            var a = new Date(unixTs*1000);
            var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            var year = a.getFullYear();
            var month = months[a.getMonth()];
            var date = a.getDate();
            var hour = a.getHours();
            var min = a.getMinutes();
            var sec = a.getSeconds();
            var time = date+' '+month+' '+year+' '+hour+':'+min+':'+sec ;
            return time;
        }

        /**********************
         * Windows
         *********************/
         Window {
             id: peerWindow
             //flags: Qt.CustomizeWindowHint | Qt.Tool | Qt.WindowCloseButtonHint
             height: 200
             width: 700
             Rectangle {
                 anchors.fill: parent
                 property var peerModel: ListModel {
                     id: peerModel
                 }
                 TableView {
                     anchors.fill: parent
                     id: peerTable
                     model: peerModel
                     TableViewColumn{width: 180; role: "addr" ; title: "Remote Address" }
                     TableViewColumn{width: 280; role: "nodeID" ; title: "Node ID" }
                     TableViewColumn{width: 100; role: "name" ; title: "Name" }
                     TableViewColumn{width: 40; role: "caps" ; title: "Capabilities" }
                 }
             }
         }

         Window {
             id: aboutWin
             visible: false
             title: "About"
             minimumWidth: 350
             maximumWidth: 350
             maximumHeight: 280
             minimumHeight: 280

             Image {
                 id: aboutIcon
                 height: 150
                 width: 150
                 fillMode: Image.PreserveAspectFit
                 smooth: true
                 source: "../facet.png"
                 x: 10
                 y: 30
             }

             Text {
                 anchors.left: aboutIcon.right
                 anchors.leftMargin: 10
                 anchors.top: parent.top
                 anchors.topMargin: 30
                 font.pointSize: 12
                 text: "<h2>Mist (0.9.0)</h2><br><h3>Development</h3>Jeffrey Wilcke<br>Viktor Trón<br>Felix Lange<br>Taylor Gerring<br>Daniel Nagy<br>Gustav Simonsson<br><h3>UX/UI</h3>Alex van de Sande<br>Fabian Vogelsteller"
             }
         }

         Window {
             id: txImportDialog
             minimumWidth: 270
             maximumWidth: 270
             maximumHeight: 50
             minimumHeight: 50
             TextField {
                 id: txImportField
                 width: 170
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.left: parent.left
                 anchors.leftMargin: 10
                 onAccepted: {
                 }
             }
             Button {
                 anchors.left: txImportField.right
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.leftMargin: 5
                 text: "Import"
                 onClicked: {
                     eth.importTx(txImportField.text)
                     txImportField.visible = false
                 }
             }
             Component.onCompleted: {
                 addrField.focus = true
             }
         }

         Window {
             id: addPeerWin
             visible: false
             minimumWidth: 400
             maximumWidth: 400
             maximumHeight: 50
             minimumHeight: 50
             title: "Connect to peer"

             TextField {
                 id: addrField
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.left: parent.left
                 anchors.right: addPeerButton.left
                 anchors.leftMargin: 10
                 anchors.rightMargin: 10
		 placeholderText: "enode://<hex node id>:<IP address>:<port>"
                 onAccepted: {
	             if(addrField.text.length != 0) {
			eth.connectToPeer(addrField.text)
			addPeerWin.visible = false
		     }
                 }
             }

             Button {
                 id: addPeerButton
                 anchors.right: parent.right
                 anchors.verticalCenter: parent.verticalCenter
                 anchors.rightMargin: 10
                 text: "Connect"
                 onClicked: {
	             if(addrField.text.length != 0) {
			eth.connectToPeer(addrField.text)
			addPeerWin.visible = false
		     }
                 }
             }
             Component.onCompleted: {
                 addrField.focus = true
             }
         }
     }
