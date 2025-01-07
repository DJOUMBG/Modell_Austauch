"""
Imports silver's internal common module from silver's python environment.
Print available silver processes.
"""
from synopsys.internal.common import _get_remaining_silver_processes
print(_get_remaining_silver_processes())
