"""Email parser for .eml files that extracts text content while dropping binary sections."""

import email
import email.policy
from email.message import EmailMessage
from typing import Dict, List, Any, Optional
import logging
import base64
import quopri
from pathlib import Path

logger = logging.getLogger(__name__)

class EmlParser:
    """Parser for .eml files that extracts text content and metadata."""
    
    def __init__(self):
        self.policy = email.policy.default
    
    def parse_eml_file(self, file_path: str) -> str:
        """Parse an .eml file and return extracted text content with metadata."""
        try:
            with open(file_path, 'rb') as f:
                msg = email.message_from_bytes(f.read(), policy=self.policy)
            
            return self._extract_email_content(msg, file_path)
        
        except Exception as e:
            logger.error(f"Error parsing .eml file {file_path}: {e}")
            return f"Error parsing email file: {e}"
    
    def _extract_email_content(self, msg: EmailMessage, file_path: str) -> str:
        """Extract text content from email message."""
        content_parts = []
        
        # Add file information
        file_name = Path(file_path).name
        content_parts.append(f"=== EMAIL FILE: {file_name} ===")
        content_parts.append("")
        
        # Extract and add headers
        headers = self._extract_headers(msg)
        if headers:
            content_parts.append("=== EMAIL HEADERS ===")
            content_parts.append(headers)
            content_parts.append("")
        
        # Extract text content
        text_content = self._extract_text_parts(msg)
        if text_content:
            content_parts.append("=== EMAIL CONTENT ===")
            content_parts.append(text_content)
            content_parts.append("")
        
        # Extract attachment information
        attachments = self._extract_attachment_info(msg)
        if attachments:
            content_parts.append("=== ATTACHMENTS ===")
            content_parts.append(attachments)
            content_parts.append("")
        
        return "\n".join(content_parts)
    
    def _extract_headers(self, msg: EmailMessage) -> str:
        """Extract important email headers."""
        important_headers = [
            'From', 'To', 'Cc', 'Bcc', 'Subject', 'Date', 
            'Message-ID', 'In-Reply-To', 'References', 'Reply-To',
            'Return-Path', 'Delivered-To', 'X-Original-To'
        ]
        
        header_lines = []
        
        for header in important_headers:
            value = msg.get(header)
            if value:
                # Handle multi-line headers
                if isinstance(value, str):
                    # Clean up header value
                    clean_value = ' '.join(value.split())
                    header_lines.append(f"{header}: {clean_value}")
        
        # Add any other interesting headers
        for key, value in msg.items():
            if key not in important_headers and not key.startswith('X-'):
                if isinstance(value, str):
                    clean_value = ' '.join(value.split())
                    header_lines.append(f"{key}: {clean_value}")
        
        return "\n".join(header_lines)
    
    def _extract_text_parts(self, msg: EmailMessage) -> str:
        """Extract text content from email parts."""
        text_parts = []
        
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == 'text/plain':
                    text_content = self._get_part_content(part)
                    if text_content:
                        text_parts.append("--- TEXT/PLAIN ---")
                        text_parts.append(text_content)
                        text_parts.append("")
                
                elif part.get_content_type() == 'text/html':
                    html_content = self._get_part_content(part)
                    if html_content:
                        # Convert HTML to readable text (basic conversion)
                        text_content = self._html_to_text(html_content)
                        if text_content:
                            text_parts.append("--- TEXT/HTML (converted) ---")
                            text_parts.append(text_content)
                            text_parts.append("")
        else:
            # Single part message
            if msg.get_content_type() in ['text/plain', 'text/html']:
                content = self._get_part_content(msg)
                if content:
                    if msg.get_content_type() == 'text/html':
                        content = self._html_to_text(content)
                    text_parts.append(content)
        
        return "\n".join(text_parts)
    
    def _get_part_content(self, part: EmailMessage) -> Optional[str]:
        """Extract content from a message part."""
        try:
            # Try to get content as string
            content = part.get_content()
            if isinstance(content, str):
                return content.strip()
            
            # Fallback: try to decode payload manually
            payload = part.get_payload(decode=True)
            if payload:
                # Try different encodings
                for encoding in ['utf-8', 'latin-1', 'cp1252']:
                    try:
                        return payload.decode(encoding).strip()
                    except UnicodeDecodeError:
                        continue
            
            return None
        
        except Exception as e:
            logger.warning(f"Error extracting content from email part: {e}")
            return None
    
    def _html_to_text(self, html_content: str) -> str:
        """Basic HTML to text conversion."""
        try:
            # Try to use html2text if available
            try:
                import html2text
                h = html2text.HTML2Text()
                h.ignore_links = False
                h.ignore_images = True
                return h.handle(html_content)
            except ImportError:
                pass
            
            # Fallback: basic HTML tag removal
            import re
            # Remove script and style elements
            html_content = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', html_content, flags=re.DOTALL | re.IGNORECASE)
            # Remove HTML tags
            text = re.sub(r'<[^>]+>', '', html_content)
            # Clean up whitespace
            text = re.sub(r'\s+', ' ', text)
            # Decode HTML entities
            import html
            text = html.unescape(text)
            return text.strip()
        
        except Exception as e:
            logger.warning(f"Error converting HTML to text: {e}")
            return html_content  # Return original if conversion fails
    
    def _extract_attachment_info(self, msg: EmailMessage) -> str:
        """Extract information about attachments without including binary content."""
        attachments = []
        
        if msg.is_multipart():
            for part in msg.walk():
                # Skip text parts and the main message
                if part.get_content_type().startswith('text/') or part == msg:
                    continue
                
                # Get attachment info
                filename = part.get_filename()
                content_type = part.get_content_type()
                content_disposition = part.get('Content-Disposition', '')
                
                # Calculate size if possible
                size_info = ""
                try:
                    payload = part.get_payload(decode=False)
                    if payload:
                        if isinstance(payload, str):
                            # Estimate decoded size for base64
                            if 'base64' in part.get('Content-Transfer-Encoding', '').lower():
                                estimated_size = len(payload) * 3 // 4
                                size_info = f" (estimated size: {estimated_size} bytes)"
                            else:
                                size_info = f" (size: {len(payload)} bytes)"
                except Exception:
                    pass
                
                attachment_info = f"- File: {filename or 'unnamed'}"
                attachment_info += f"\n  Type: {content_type}"
                if content_disposition:
                    attachment_info += f"\n  Disposition: {content_disposition}"
                if size_info:
                    attachment_info += f"\n  {size_info.strip()}"
                
                attachments.append(attachment_info)
        
        return "\n\n".join(attachments) if attachments else ""

# Global instance
eml_parser = EmlParser()

def parse_eml_file(file_path: str) -> str:
    """Convenience function to parse an .eml file."""
    return eml_parser.parse_eml_file(file_path)
