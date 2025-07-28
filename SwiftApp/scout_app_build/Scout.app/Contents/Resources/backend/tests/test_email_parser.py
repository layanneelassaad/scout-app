#!/usr/bin/env python3
"""Test script for the email parser functionality."""

import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import the modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from email_parser import parse_eml_file

def create_sample_eml(file_path: str):
    """Create a sample .eml file for testing."""
    sample_email = '''From: john.doe@example.com
To: jane.smith@company.com
Cc: team@company.com
Subject: Project Update - Q4 Report
Date: Mon, 15 Jan 2024 10:30:00 -0500
Message-ID: <abc123@example.com>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="boundary123"

--boundary123
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 7bit

Hi Jane,

I hope this email finds you well. I'm writing to provide an update on the Q4 project.

Key accomplishments:
- Completed user research phase
- Delivered initial wireframes
- Conducted stakeholder interviews

Next steps:
- Finalize design mockups
- Begin development sprint
- Schedule user testing sessions

Please let me know if you have any questions or concerns.

Best regards,
John Doe
Senior Product Manager
Example Corp

--boundary123
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 7bit

<html>
<body>
<p>Hi Jane,</p>
<p>I hope this email finds you well. I'm writing to provide an update on the <strong>Q4 project</strong>.</p>
<h3>Key accomplishments:</h3>
<ul>
<li>Completed user research phase</li>
<li>Delivered initial wireframes</li>
<li>Conducted stakeholder interviews</li>
</ul>
<h3>Next steps:</h3>
<ul>
<li>Finalize design mockups</li>
<li>Begin development sprint</li>
<li>Schedule user testing sessions</li>
</ul>
<p>Please let me know if you have any questions or concerns.</p>
<p>Best regards,<br>
John Doe<br>
Senior Product Manager<br>
Example Corp</p>
</body>
</html>

--boundary123
Content-Type: application/pdf
Content-Disposition: attachment; filename="q4_report.pdf"
Content-Transfer-Encoding: base64

JVBERi0xLjQKJcOkw7zDtsO4CjIgMCBvYmoKPDwKL0xlbmd0aCAzIDAgUgo+PgpzdHJlYW0KeJzLSM3PyVEozy/KSVEoLU5NLMnMz1FIzkksLU4tykvMTVUoLU4tykvMTQUAWQsOGAplbmRzdHJlYW0KZW5kb2JqCg==

--boundary123
Content-Type: image/png
Content-Disposition: attachment; filename="chart.png"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==

--boundary123--
'''
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(sample_email)
    
    print(f"Created sample email file: {file_path}")

def test_email_parser():
    """Test the email parser with a sample .eml file."""
    # Create a temporary test file
    test_file = "/tmp/test_email.eml"
    
    try:
        # Create sample email
        create_sample_eml(test_file)
        
        # Parse the email
        print("\n" + "="*60)
        print("TESTING EMAIL PARSER")
        print("="*60)
        
        parsed_content = parse_eml_file(test_file)
        
        print("\nPARSED EMAIL CONTENT:")
        print("-" * 40)
        print(parsed_content)
        print("-" * 40)
        
        # Verify key components are present
        checks = [
            ("File name included", "test_email.eml" in parsed_content),
            ("Headers section", "=== EMAIL HEADERS ===" in parsed_content),
            ("From header", "From: john.doe@example.com" in parsed_content),
            ("Subject header", "Subject: Project Update" in parsed_content),
            ("Content section", "=== EMAIL CONTENT ===" in parsed_content),
            ("Plain text content", "Key accomplishments:" in parsed_content),
            ("HTML content converted", "Q4 project" in parsed_content),
            ("Attachments section", "=== ATTACHMENTS ===" in parsed_content),
            ("PDF attachment info", "q4_report.pdf" in parsed_content),
            ("Image attachment info", "chart.png" in parsed_content),
            ("Binary content excluded", "JVBERi0xLjQK" not in parsed_content)  # Base64 content should be excluded
        ]
        
        print("\nVERIFICATION CHECKS:")
        print("-" * 40)
        all_passed = True
        for check_name, passed in checks:
            status = "✓ PASS" if passed else "✗ FAIL"
            print(f"{status}: {check_name}")
            if not passed:
                all_passed = False
        
        print("-" * 40)
        if all_passed:
            print("🎉 ALL TESTS PASSED! Email parser is working correctly.")
        else:
            print("❌ Some tests failed. Please check the implementation.")
        
        return all_passed
        
    except Exception as e:
        print(f"Error during testing: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    finally:
        # Clean up test file
        if os.path.exists(test_file):
            os.remove(test_file)
            print(f"\nCleaned up test file: {test_file}")

if __name__ == "__main__":
    success = test_email_parser()
    sys.exit(0 if success else 1)
