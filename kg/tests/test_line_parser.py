#!/usr/bin/env python3
"""Test script for the line format parser."""

import json
from line_format_parser import LineFormatParser

def test_parser():
    """Test the line format parser with various inputs."""
    
    # Test 1: Basic parsing
    print("Test 1: Basic parsing")
    test_input = """E|John Smith|Person|Senior software engineer
E|Acme Corp|Organization|Technology company
E|Project X|Project|Secret AI project
R|John Smith|works_at|Acme Corp
R|John Smith|leads|Project X
R|File:report.pdf|mentions|John Smith"""
    
    result = LineFormatParser.parse(test_input)
    print(json.dumps(result, indent=2))
    print("\n" + "="*50 + "\n")
    
    # Test 2: With properties
    print("Test 2: With properties")
    test_input_props = """E|Jane Doe|Person|Data scientist|email=jane@example.com;department=R&D
E|DataCorp|Organization|Data analytics firm|founded=2015;size=medium
R|Jane Doe|works_at|DataCorp|since=2020;role=lead"""
    
    result_props = LineFormatParser.parse(test_input_props)
    print(json.dumps(result_props, indent=2))
    print("\n" + "="*50 + "\n")
    
    # Test 3: Edge cases
    print("Test 3: Edge cases (empty lines, malformed)")
    test_edge = """E|Bob|Person|Engineer

R|Bob|knows|Alice
X|Invalid|Line|Type
E|Missing|Description
R|Too|Few
E|Extra Spaces| Person | Developer """
    
    result_edge = LineFormatParser.parse(test_edge)
    print(json.dumps(result_edge, indent=2))
    print("\n" + "="*50 + "\n")
    
    # Test 4: Show format instructions
    print("Format Instructions:")
    print(LineFormatParser.format_instructions())
    print("\n" + "="*50 + "\n")
    
    # Test 5: Show format example
    print("Format Example:")
    print(LineFormatParser.format_example())

if __name__ == "__main__":
    test_parser()
