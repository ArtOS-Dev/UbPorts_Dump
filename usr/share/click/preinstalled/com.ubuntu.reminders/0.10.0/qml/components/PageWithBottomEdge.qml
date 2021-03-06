/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
    Example:

    MainView {
        objectName: "mainView"

        applicationName: "com.ubuntu.developer.boiko.bottomedge"

        width: units.gu(100)
        height: units.gu(75)

        Component {
            id: pageComponent

            PageWithBottomEdge {
                id: mainPage
                title: i18n.tr("Main Page")

                Rectangle {
                    anchors.fill: parent
                    color: Suru.backgroundColor
                }

                bottomEdgePageComponent: Page {
                    title: "Contents"
                    anchors.fill: parent
                    //anchors.topMargin: contentsPage.flickable.contentY

                    ListView {
                        anchors.fill: parent
                        model: 50
                        delegate: ListItems.Standard {
                            text: "One Content Item: " + index
                        }
                    }
                }
                bottomEdgeTitle: i18n.tr("Bottom edge action")
            }
        }

        PageStack {
            id: stack
            Component.onCompleted: stack.push(pageComponent)
        }
    }

*/

import QtQuick 2.4
import QtQuick.Controls.Suru 2.2
import Ubuntu.Components 1.3
import Evernote 0.1

Page {
    id: page

    property alias bottomEdgePageComponent: edgeLoader.sourceComponent
    property alias bottomEdgePageSource: edgeLoader.source
    property alias bottomEdgeTitle: tipLabel.text
    property alias bottomEdgeEnabled: bottomEdge.visible
    property int bottomEdgeExpandThreshold: page.height * 0.2
    property int bottomEdgeExposedArea: bottomEdge.state !== "expanded" ? (page.height - bottomEdge.y - bottomEdge.tipHeight) : _areaWhenExpanded
    property bool reloadBottomEdgePage: true

    readonly property alias bottomEdgePage: edgeLoader.item
    readonly property bool isReady: (tip.opacity === 0.0)
    readonly property bool isCollapsed: (tip.opacity === 1.0)
    readonly property bool bottomEdgePageLoaded: (edgeLoader.status == Loader.Ready)
    property var temporaryProperties: null

    property bool bottomEdgeLabelVisible: true

    property bool _showEdgePageWhenReady: false
    property int _areaWhenExpanded: 0

    signal bottomEdgeReleased()
    signal bottomEdgeDismissed()

    readonly property bool bottomEdgeContentShown: bottomEdge.y < page.height


    function showBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
        temporaryProperties = properties
        _showEdgePageWhenReady = true
    }

    function setBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
    }

    function _pushPage()
    {
        if (edgeLoader.status === Loader.Ready) {
            edgeLoader.item.active = true


            if (edgeLoader.item.flickable) {
                edgeLoader.item.flickable.contentY = -page.header.height
                edgeLoader.item.flickable.returnToBounds()
            }
            if (edgeLoader.item.ready)
                edgeLoader.item.ready()


            NotesStore.createNote(i18n.tr("Untitled"), filterNotebookGuid);
        }
    }


    Component.onCompleted: {
        // avoid a binding on the expanded height value
        var expandedHeight = height;
        _areaWhenExpanded = expandedHeight;
    }

    onActiveChanged: {
        if (active) {
            bottomEdge.state = "collapsed"
        }
    }

    onBottomEdgePageLoadedChanged: {
        if (_showEdgePageWhenReady && bottomEdgePageLoaded) {
            bottomEdge.state = "expanded"
            _showEdgePageWhenReady = false
        }
    }

    Rectangle {
        id: bgVisual

        visible: bottomEdgeLabelVisible

        color: Suru.foregroundColor
        anchors.fill: page
        opacity: 0.7 * ((page.height - bottomEdge.y) / page.height)
        z: 1
    }

    Rectangle {
        id: bottomEdge
        objectName: "bottomEdge"

        readonly property int tipHeight: units.gu(3)
        readonly property int pageStartY: 0

        visible: bottomEdgeLabelVisible

        z: 1
        color: Suru.backgroundColor
        parent: page
        anchors {
            left: parent.left
            right: parent.right
        }
        height: page.height
        y: height

        Rectangle {
            id: shadow

            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(1)
            y: -height
            opacity: 0.0
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
            }
        }

        Item {
            id: tipContainer
            objectName: "bottomEdgeTip"

            width: childrenRect.width
            height: bottomEdge.tipHeight
            clip: true
            y: -bottomEdge.tipHeight
            anchors.horizontalCenter: parent.horizontalCenter

            UbuntuShape {
                id: tip

                width: tipLabel.paintedWidth + units.gu(6)
                height: bottomEdge.tipHeight + units.gu(1)
                color: Suru.backgroundColor
                Label {
                    id: tipLabel

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: bottomEdge.tipHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        MouseArea {
            preventStealing: true
            drag.axis: Drag.YAxis
            drag.target: bottomEdge
            drag.minimumY: bottomEdge.pageStartY
            drag.maximumY: page.height

            anchors {
                left: parent.left
                right: parent.right
            }
            height: bottomEdge.tipHeight
            y: -height

            onReleased: {
                page.bottomEdgeReleased()
                if (bottomEdge.y < (page.height - bottomEdgeExpandThreshold - bottomEdge.tipHeight)) {
                    bottomEdge.state = "expanded"
                } else {
                    bottomEdge.state = "collapsed"
                    bottomEdge.y = bottomEdge.height
                }
            }

            onPressed: {
                bottomEdge.state = "floating"
                bottomEdge.y -= bottomEdge.tipHeight
            }
        }

        Behavior on y {
            UbuntuNumberAnimation {}
        }

        state: "collapsed"
        states: [
            State {
                name: "collapsed"
                PropertyChanges {
                    target: bottomEdge
                    y: bottomEdge.height
                }
                PropertyChanges {
                    target: tip
                    opacity: 1.0
                }
            },
            State {
                name: "expanded"
                PropertyChanges {
                    target: bottomEdge
                    y: bottomEdge.pageStartY
                }
                PropertyChanges {
                    target: tip
                    opacity: 0.0
                }
            },
            State {
                name: "floating"
                PropertyChanges {
                    target: shadow
                    opacity: 1.0
                }
            }
        ]

        transitions: [
            Transition {
                to: "expanded"
                SequentialAnimation {
                    UbuntuNumberAnimation {
                        targets: [bottomEdge,tip]
                        properties: "y,opacity"
                        duration: UbuntuAnimation.SlowDuration
                    }
                    ScriptAction {
                        script: page._pushPage()
                    }
                }
            },
            Transition {
                from: "expanded"
                to: "collapsed"
                SequentialAnimation {
                    ScriptAction {
                        script: {
                            edgeLoader.item.parent = edgeLoader
                            edgeLoader.item.anchors.fill = edgeLoader
                            edgeLoader.item.active = false
                        }
                    }
                    UbuntuNumberAnimation {
                        targets: [bottomEdge,tip]
                        properties: "y,opacity"
                        duration: UbuntuAnimation.SlowDuration
                    }
                    ScriptAction {
                        script: {
                            // destroy current bottom page
                            if (page.reloadBottomEdgePage) {
                                edgeLoader.active = false
                                // remove properties from old instance
                                if (edgeLoader.source !== "") {
                                    var properties = {}
                                    if (temporaryProperties !== null) {
                                        properties = temporaryProperties
                                        temporaryProperties = null
                                    }

                                    edgeLoader.setSource(edgeLoader.source, properties)
                                }
                            }

                            // notify
                            page.bottomEdgeDismissed()

                            // load a new bottom page in memory
                            edgeLoader.active = true
                        }
                    }
                }
            },
            Transition {
                from: "floating"
                to: "collapsed"
                UbuntuNumberAnimation {
                    targets: [bottomEdge,tip]
                    properties: "y,opacity"
                }
            }
        ]

        Loader {
            id: edgeLoader

            z: 1
            active: true
            asynchronous: true
            anchors.fill: parent
            visible: page.bottomEdgeContentShown

            //WORKAROUND: The SDK move the page contents down to allocate space for the header we need to avoid that during the page dragging
            Binding {
                target: edgeLoader
                property: "anchors.topMargin"
                value: edgeLoader.item && edgeLoader.item.flickable ? edgeLoader.item.flickable.contentY : 0
                when: (edgeLoader.status === Loader.Ready && !page.isReady)
            }

            onLoaded: {
                if (page.isReady && edgeLoader.item.active != true) {
                    page._pushPage()
                }
            }
        }
    }
}
