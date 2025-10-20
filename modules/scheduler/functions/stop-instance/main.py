"""
Cloud Function to stop a GCP Compute Engine instance.

This function is triggered by Cloud Scheduler to stop the VPN instance
after business hours for cost optimization.

Uses lightweight HTTP API calls instead of heavy client libraries.
"""

import os
import functions_framework
from google.auth import default
from google.auth.transport.requests import AuthorizedSession


def get_instance_config():
    """
    Get and validate instance configuration from environment variables.
    
    Returns:
        tuple: (project_id, zone, instance_name) or (None, None, None) if invalid
    """
    project_id = os.environ.get("PROJECT_ID")
    zone = os.environ.get("ZONE")
    instance_name = os.environ.get("INSTANCE_NAME")
    
    if not all([project_id, zone, instance_name]):
        return None, None, None
    
    return project_id, zone, instance_name


def manage_instance(action, project_id, zone, instance_name):
    """
    Manage GCP Compute Engine instance (start or stop).
    
    Args:
        action: 'start' or 'stop'
        project_id: GCP project ID
        zone: Instance zone
        instance_name: Instance name
        
    Returns:
        tuple: (response_dict, status_code)
    """
    action_verb = action.capitalize()
    action_past = "started" if action == "start" else "stopped"
    action_state = "running" if action == "start" else "stopped"
    
    print(f"{action_verb}ing instance: {instance_name} in {zone}")
    
    try:
        # Get default credentials
        credentials, _ = default()
        session = AuthorizedSession(credentials)
        
        # Call Compute Engine API
        url = f"https://compute.googleapis.com/compute/v1/projects/{project_id}/zones/{zone}/instances/{instance_name}/{action}"
        response = session.post(url)
        
        if response.status_code == 200:
            print(f"Successfully {action_past} instance {instance_name}")
            return {
                "success": True,
                "message": f"Instance {instance_name} {action} operation initiated"
            }, 200
        elif response.status_code == 400:
            # Instance might already be in the target state
            error_msg = response.json().get('error', {}).get('message', 'Unknown error')
            print(f"Instance might already be {action_state}: {error_msg}")
            return {
                "success": True,
                "message": f"Instance {instance_name} is already {action_state} or {action}ing"
            }, 200
        else:
            error_msg = response.json().get('error', {}).get('message', 'Unknown error')
            print(f"Error {action}ing instance: {error_msg}")
            return {
                "success": False,
                "message": f"Error {action}ing instance: {error_msg}"
            }, 500
            
    except Exception as e:
        print(f"Exception {action}ing instance: {e}")
        return {
            "success": False,
            "message": f"Exception: {str(e)}"
        }, 500


@functions_framework.http
def stop_instance_handler(request):
    """
    HTTP Cloud Function entry point to stop instance.
    
    Expected environment variables:
    - PROJECT_ID: GCP project ID
    - ZONE: Instance zone
    - INSTANCE_NAME: Instance name
    
    Returns:
        HTTP response with operation status
    """
    # Get and validate configuration
    project_id, zone, instance_name = get_instance_config()
    
    if not project_id:
        return {
            "success": False,
            "message": "Missing required environment variables"
        }, 500
    
    # Perform stop operation
    return manage_instance("stop", project_id, zone, instance_name)
