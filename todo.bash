#!/usr/bin/env bash
# This file can be sourced or executed.
# More information below at the "Execution" section

# Todo Function
function todo() {
    local conf="${HOME}/.config/.todo"
    [[ -f "${conf}" ]] || touch "${conf}"  # Create config file if it doesn't exist
    sed -i '/^\s*$/d' "${conf}"  # Remove empty lines

    local mode
    case "$1" in
        -h|--help)    mode=0 ;;
        -r|--remove)  mode=1 ;;
        -a|--add)     mode=2 ;;
        *[0-9]*)      mode=3 ;;
        -q|--quiet)   mode=4 ;;
        *)            mode=5 ;;
    esac

    if [[ "${mode}" =~ ^[0-5]$ ]]; then
        case "${mode}" in
            0)  # Help message
                cat << EOF

@Usage: todo [INDEX]...
      todo [OPTIONS [INDEX|ITEM|DATE]...]...
List, add, or remove todo items.

@OPTIONS:
    -h, --help      This help message.
    -r, --remove    Remove an item by INDEX number. 
    -a, --add       Add an item by ITEM with an optional DUE DATE (format: YYYY-MM-DD).
    -q, --quiet     No error messages.
@INDEX:
    Integers        Index number of item.
@ITEM:
    String          Todo ITEM.
@EXAMPLES:
    todo            List all items in todo list.
    todo 1          List 1st ITEM in todo list. 
    todo -a "Something to do" "2024-10-30"  Add a todo item with due date.
    todo -r 1       Remove item at index #1.

EOF
                return 0
                ;;
            1)  # Remove an item
                if [[ -z "$2" ]]; then
                    echo "Error: Please provide an index number to remove."
                    return 1
                fi
                if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                    echo "Error: Index must be a valid positive integer."
                    return 1
                fi
                if ! sed -n "${2}p" "${conf}" >/dev/null; then
                    echo "Error: No item found at index $2."
                    return 1
                fi
                sed -i -e "${2}d" "${conf}" || {
                    echo "Error: Failed to remove item."
                    return 1
                }
                echo "Item $2 removed."
                return 0
                ;;
            2)  # Add an item
                if [[ -z "$2" ]]; then
                    echo "Error: Please provide an item to add."
                    return 1
                fi
                local due_date=""
                if [[ ! -z "$3" ]]; then
                    due_date=" (Due: $3)"
                fi
                echo "$2$due_date" >> "${conf}" || {
                    echo "Error: Failed to add item."
                    return 1
                }
                echo "Item added: $2$due_date"
                return 0
                ;;
            3)  # List a specific item
                if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                    echo "Error: Index must be a valid positive integer."
                    return 1
                fi
                readarray -t array < "${conf}"
                if [[ -z "${array[$(( $1 - 1 ))]}" ]]; then
                    echo "Error: No item found at index $1."
                    return 1
                fi
                echo "${array[$(( $1 - 1 ))]}"
                return 0
                ;;
            4)  # Quiet mode
                return 0
                ;;
            5)  # List all items
                readarray -t array < "${conf}"
                if [[ ${#array[@]} -eq 0 ]]; then
                    [[ "${mode}" -ne 4 ]] && echo "No items in the TODO list."
                    return 0
                fi
                for index in "${!array[@]}"; do
                    echo "[$(( index + 1 ))]: ${array[index]}"
                done
                return 0
                ;;
        esac
    else
        echo "Error: Invalid command. Use -h or --help for usage information."
        return 1
    fi
}

# Tab completion
if [ "$_" == "$0" ]; then
    complete -W '-h --help -r --remove -a --add -q --quiet' todo
else
    todo "$@"
fi
