"""Condition evaluation utilities for the knowledge graph query engine."""

import re
import logging
from typing import Dict, List, Any, Optional

logger = logging.getLogger(__name__)

class ConditionEvaluator:
    """Handles evaluation of various condition types against node data."""
    
    @staticmethod
    def evaluate_condition(node_data: Dict[str, Any], condition: Any) -> bool:
        """Recursively evaluate a condition against node data."""
        if isinstance(condition, dict):
            if 'all' in condition:
                return all(ConditionEvaluator.evaluate_condition(node_data, c) for c in condition['all'])
            if 'any' in condition:
                return any(ConditionEvaluator.evaluate_condition(node_data, c) for c in condition['any'])
            if 'not' in condition:
                return not ConditionEvaluator.evaluate_condition(node_data, condition['not'])
        
            # Handle direct property conditions
            for field_name, field_condition in condition.items():
                if field_name not in ['all', 'any', 'not']:
                    if isinstance(field_condition, dict):
                        # Handle operator-based conditions
                        for op, value in field_condition.items():
                            if not ConditionEvaluator.evaluate_property_condition(node_data, field_name, op, value):
                                return False
                    else:
                        # Direct equality check
                        if node_data.get(field_name) != field_condition:
                            return False
            return True
        
        if isinstance(condition, str):
            return ConditionEvaluator.parse_string_condition(node_data, condition)
        
        return False

    @staticmethod
    def parse_string_condition(node_data: Dict[str, Any], condition_str: str) -> bool:
        """Parse and evaluate a single string condition like 'age > 30'."""
        match = re.match(r'\s*(\w+)\s*([><=!]+|CONTAINS)\s*([\"\'].*[\"\']|\S+)\s*', condition_str, re.IGNORECASE)
        if not match:
            return False

        field, op, value_str = match.groups()
        op = op.upper()
        
        # Get the actual value from the node data
        field_value = node_data.get(field)
        if field_value is None:
            return False

        # Clean up the value from the condition string
        value = value_str.strip('"\'')

        if op == 'CONTAINS':
            return value.lower() in str(field_value).lower()

        # For comparison operators, try to cast to float
        try:
            field_value_num = float(field_value)
            value_num = float(value)
            
            if op == '>': return field_value_num > value_num
            if op == '<': return field_value_num < value_num
            if op == '>=': return field_value_num >= value_num
            if op == '<=': return field_value_num <= value_num
            if op == '==': return field_value_num == value_num
            if op == '!=': return field_value_num != value_num
        except (ValueError, TypeError):
            # Fallback to string comparison
            if op == '==': return str(field_value) == value
            if op == '!=': return str(field_value) != value

        return False

    @staticmethod
    def evaluate_property_condition(node_data: Dict[str, Any], field_name: str, operator: str, value: Any) -> bool:
        """Evaluate a property condition with an operator."""
        field_value = node_data.get(field_name)
        if field_value is None:
            return False
        
        operator = operator.lower()
        
        if operator in ['equals', 'eq', '=']:
            return field_value == value
        elif operator in ['not_equals', 'ne', '!=']:
            return field_value != value
        elif operator in ['gt', '>']:
            try:
                return float(field_value) > float(value)
            except (ValueError, TypeError):
                return str(field_value) > str(value)
        elif operator in ['lt', '<']:
            try:
                return float(field_value) < float(value)
            except (ValueError, TypeError):
                return str(field_value) < str(value)
        elif operator in ['gte', '>=']:
            try:
                return float(field_value) >= float(value)
            except (ValueError, TypeError):
                return str(field_value) >= str(value)
        elif operator in ['lte', '<=']:
            try:
                return float(field_value) <= float(value)
            except (ValueError, TypeError):
                return str(field_value) <= str(value)
        elif operator in ['contains', 'in']:
            return str(value).lower() in str(field_value).lower()
        elif operator in ['startswith', 'starts_with']:
            return str(field_value).lower().startswith(str(value).lower())
        elif operator in ['endswith', 'ends_with']:
            return str(field_value).lower().endswith(str(value).lower())
        elif operator == 'regex':
            return bool(re.search(str(value), str(field_value), re.IGNORECASE))
        else:
            logger.warning(f"Unknown operator: {operator}")
            return False

    @staticmethod
    def evaluate_field_condition(node_data: Dict[str, Any], field_name: str, field_spec: Dict[str, Any]) -> bool:
        """Evaluate a field-specific condition like description: contains: weapon."""
        field_value = node_data.get(field_name, '')
        if not field_value:
            return False
        
        field_value_str = str(field_value).lower()
        
        # Handle different field condition types
        if 'contains' in field_spec:
            search_term = str(field_spec['contains']).lower()
            return search_term in field_value_str
        elif 'equals' in field_spec:
            return str(field_spec['equals']).lower() == field_value_str
        elif 'regex' in field_spec:
            pattern = field_spec['regex']
            return bool(re.search(pattern, field_value_str, re.IGNORECASE))
        elif 'startswith' in field_spec:
            return field_value_str.startswith(str(field_spec['startswith']).lower())
        elif 'endswith' in field_spec:
            return field_value_str.endswith(str(field_spec['endswith']).lower())
        
        return False

    @staticmethod
    def evaluate_filter_field(node_data: Dict[str, Any], field_name: str, condition: Any) -> bool:
        """Evaluate a single filter field condition."""
        field_value = node_data.get(field_name, '')
        if not field_value:
            return False
        
        field_value_str = str(field_value).lower()
        
        if isinstance(condition, str):
            # Simple string match (case-insensitive)
            return condition.lower() in field_value_str
        elif isinstance(condition, dict):
            # Handle regex and other operators
            if 'regex' in condition:
                pattern = condition['regex']
                return bool(re.search(pattern, field_value_str, re.IGNORECASE))
            elif 'contains' in condition:
                search_term = str(condition['contains']).lower()
                return search_term in field_value_str
            elif 'equals' in condition:
                return str(condition['equals']).lower() == field_value_str
            elif 'startswith' in condition:
                return field_value_str.startswith(str(condition['startswith']).lower())
            elif 'endswith' in condition:
                return field_value_str.endswith(str(condition['endswith']).lower())
        
        return False
