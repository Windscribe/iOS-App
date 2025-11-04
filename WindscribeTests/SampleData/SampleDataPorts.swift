//
//  SampleDataPorts.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

class SampleDataPorts {
    static let portMapsJSON = """
    [
        {
            "protocol": "tcp",
            "heading": "TCP",
            "use": "Auto",
            "ports": ["443", "80", "8080"],
            "legacy_ports": []
        },
        {
            "protocol": "udp",
            "heading": "UDP",
            "use": "Auto",
            "ports": ["53", "1194"],
            "legacy_ports": []
        }
    ]
    """

    static let portMapListJSON = """
    {
        "data": {
            "portmap": [
                {
                    "protocol": "tcp",
                    "heading": "TCP",
                    "use": "Auto",
                    "ports": ["443", "80", "8080"],
                    "legacy_ports": []
                },
                {
                    "protocol": "udp",
                    "heading": "UDP",
                    "use": "Auto",
                    "ports": ["53", "1194"],
                    "legacy_ports": []
                }
            ]
        }
    }
    """

    static let portMapListWithSuggestedJSON = """
    {
        "data": {
            "portmap": [
                {
                    "protocol": "tcp",
                    "heading": "TCP",
                    "use": "Auto",
                    "ports": ["443", "80", "8080"],
                    "legacy_ports": []
                },
                {
                    "protocol": "udp",
                    "heading": "UDP",
                    "use": "Auto",
                    "ports": ["53", "1194"],
                    "legacy_ports": []
                }
            ],
            "suggested": {
                "protocol": "udp",
                "port": 443
            }
        }
    }
    """

    static let singleUDPPortMapListJSON = """
    {
        "data": {
            "portmap": [
                {
                    "protocol": "udp",
                    "heading": "UDP",
                    "use": "Auto",
                    "ports": ["443"],
                    "legacy_ports": []
                }
            ]
        }
    }
    """

    static let emptyPortMapListJSON = """
    {
        "data": {
            "portmap": []
        }
    }
    """

    static let suggestedPortsJSON = """
    {
        "protocol": "udp",
        "port": 443
    }
    """
}
