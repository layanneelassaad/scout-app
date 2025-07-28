#!/usr/bin/env python3
"""
Extract emails from .mbox file into separate .eml files
Optimized for large files - processes emails one at a time without loading entire file
"""

import mailbox
import os
import sys
import argparse
from pathlib import Path


def extract_emails_from_mbox(mbox_path, output_dir, max_emails=20):
    """
    Extract emails from mbox file to individual .eml files
    
    Args:
        mbox_path: Path to the .mbox file
        output_dir: Directory to save extracted emails
        max_emails: Maximum number of emails to extract (default: 20)
    """
    # Create output directory if it doesn't exist
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    print(f"Opening mbox file: {mbox_path}")
    print(f"Output directory: {output_path}")
    print(f"Extracting first {max_emails} emails...\n")
    
    try:
        # Open mbox file - this doesn't load entire file into memory
        mbox = mailbox.mbox(mbox_path)
        
        extracted_count = 0
        
        # Iterate through messages
        for i, message in enumerate(mbox):
            if extracted_count >= max_emails:
                break
                
            try:
                # Get email metadata for filename
                subject = message.get('Subject', 'no_subject')
                # Clean subject for filename
                subject_clean = "".join(c for c in subject if c.isalnum() or c in (' ', '-', '_')).rstrip()[:50]
                
                # Create filename
                filename = f"{i:04d}_{subject_clean}.eml"
                filepath = output_path / filename
                
                # Write email to file
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(str(message))
                
                extracted_count += 1
                print(f"Extracted: {filename}")
                
            except Exception as e:
                print(f"Error extracting email {i}: {e}")
                continue
        
        print(f"\nSuccessfully extracted {extracted_count} emails")
        return extracted_count
        
    except Exception as e:
        print(f"Error opening mbox file: {e}")
        return 0


def main():
    parser = argparse.ArgumentParser(description='Extract emails from .mbox file')
    parser.add_argument('mbox_file', help='Path to the .mbox file')
    parser.add_argument('-o', '--output', default='extracted_emails', 
                        help='Output directory (default: extracted_emails)')
    parser.add_argument('-n', '--number', type=int, default=20,
                        help='Number of emails to extract (default: 20)')
    
    args = parser.parse_args()
    
    # Check if mbox file exists
    if not os.path.exists(args.mbox_file):
        print(f"Error: mbox file '{args.mbox_file}' not found")
        sys.exit(1)
    
    # Extract emails
    count = extract_emails_from_mbox(args.mbox_file, args.output, args.number)
    
    if count > 0:
        print(f"\nEmails saved to: {os.path.abspath(args.output)}")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
