################################################################################
# PROCESS VALID ADDONS IF AVAILABLE
################################################################################

################################################################################
# CONSTANTS
#   A set of constants that are used for some of the more gnarly make action. 
################################################################################

EMPTY_SPACE :=
EMPTY_SPACE += 

TRUE := NON_EMPTY_STRING
FALSE := 

ESCAPED_DELIMITER := <?--DELIMITER--?>

FIND_TYPE_DIRECTORY:=d
FIND_TYPE_FILE:=f

################################################################################
# FUNCTION FUNC_DO_NOTHING
#   A "do nothing" function sometimes called to help make if/else statements 
#   more readable. 
################################################################################

define FUNC_DO_NOTHING
endef

################################################################################
# FUNCTION FUNC_REMOVE_DUPLICATE_ADDONS
#   Define a function to remove duplicates without using $(sort ..), 
#   because ($sort ...) will place the list in lexicographic order.  In 
#   many cases we want to respect an existing order.
#   
#   This function is not for the faint of heart.
#
#   For more information about $(strip ...), $(word, ...), see:
#
#       http://www.gnu.org/software/make/manual/html_node/Text-Functions.html
#
#   For more information about $(call ...) see:
#
#       http://www.gnu.org/software/make/manual/html_node/Call-Function.html
#
################################################################################

define FUNC_REMOVE_DUPLICATES_PRESERVE_ORDER
    $(if $1,                                                                   \
        $(strip                                                                \
            $(word 1,$1)                                                       \
            $(call FUNC_REMOVE_DUPLICATES_PRESERVE_ORDER,$(filter-out $(word 1,$1),$1))\
        ),                                                                     \
        $(call FUNC_DO_NOTHING)                                                \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_RECURSIVE_FIND_SOURCES
#   A function that will recursively search for source files beginning in a 
#   given directory.
#
#   Example Usage:
#   
#       THE_SOURCES_FOUND :=                                                   \
#                      $(call                                                  \
#                           FUNC_RECURSIVE_FIND_SOURCES,                       \
#                           $(DIRECTORY_TO_SEARCH)                             \
#                       )                                                      \
#   Steps:
#
#   1.  Search the passed directory ($1) for the type file "f" with one of the
#       listed file extensions:
#        find $1                                                               
#           -type f                                                            
#           -name "*.mm"                                                       
#           -or                                                                
#           ...
#           -name "*.cxx"                                                      
#
#   2. Send errors to /dev/null
#
#       2> /dev/null
#
#   3. Exclude all hidden directories and files.
#
#       | grep -v "/\.[^\.]" )
#
################################################################################

define FUNC_RECURSIVE_FIND_SOURCES
    $(shell                                                                    \
        find $1                                                                \
            -type f                                                            \
            -name "*.mm"                                                       \
            -or                                                                \
            -name "*.m"                                                        \
            -or                                                                \
            -name "*.cpp"                                                      \
            -or                                                                \
            -name "*.c"                                                        \
            -or                                                                \
            -name "*.cc"                                                       \
            -or                                                                \
            -name "*.cxx"                                                      \
        2> /dev/null                                                           \
        | grep -v "/\.[^\.]"                                                   \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_RECURSIVE_FIND_SEARCH_PATHS
#   A function that will recursively search for header OR library search path 
#   directories while ignoring framework paths and hidden directories.
################################################################################

define FUNC_RECURSIVE_FIND_SEARCH_PATHS
    $(shell                                                                    \
        find $1                                                                \
            -type d                                                            \
            -not                                                               \
            -path "*.framework*"                                               \
        2> /dev/null                                                           \
        | grep -v "/\.[^\.]"                                                   \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_RECURSIVE_FIND_LIBRARIES_WITH_TYPE_AND_NAME_PATTERN
#   A function that will recursively search for libraries and frameworks and
#   will ignore anything that is hidden. 
#   
#   Arg $1 => the search directory
#   Arg #2 => the search type (f or d)
#   Arg #3 => the name pattern
#
#   See FUNC_PARSE_ADDON_TEMPLATE_HEADER_SEARCH_PATHS for an example.
################################################################################

define FUNC_RECURSIVE_FIND_LIBRARIES_WITH_TYPE_AND_NAME_PATTERN
    $(shell                                                                    \
        find $1                                                                \
            -type $2                                                           \
            -name $3                                                           \
        2> /dev/null                                                           \
        | grep -v "/\.[^\.]"                                                   \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON_TEMPLATE_HEADER_SEARCH_PATHS
#   A function that takes the path of an addon and recursively creates a list 
#   of header search paths using the standard ofxAddonTemplate structure.
#   
#   When this function finishes, a well-ordered list of header search paths for
#   the given addon is available in the following variable:
#   
#       PARSED_ADDON_HEADER_SEARCH_PATHS
################################################################################

define FUNC_PARSE_ADDON_TEMPLATE_HEADER_SEARCH_PATHS
                                                                               \
    $(eval PATH_OF_ADDON:=$(strip $1))                                         \
                                                                               \
    $(eval PARSED_ADDON_HEADER_SEARCH_PATHS:=                                  \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SEARCH_PATHS,                                  \
            $(PATH_OF_ADDON)/libs/*/src                                        \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_HEADER_SEARCH_PATHS +=                                 \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SEARCH_PATHS,                                  \
            $(PATH_OF_ADDON)/libs/*/include                                    \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_HEADER_SEARCH_PATHS +=                                 \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SEARCH_PATHS,                                  \
            $(PATH_OF_ADDON)/src                                               \
        )                                                                      \
    )                                                                          \
                                                                               \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON_TEMPLATE_SOURCES
#   A function that takes the path of an addon and recursively creates a list 
#   of all sources using the standard ofxAddonTemplate structure.
#   
#   When this function finishes, a well-ordered list of sources for
#   the given addon is available in the following variable:
#   
#       PARSED_ADDON_SOURCES
################################################################################

define FUNC_PARSE_ADDON_TEMPLATE_SOURCES
                                                                               \
    $(eval PATH_OF_ADDON:=$(strip $1))                                         \
                                                                               \
    $(eval PARSED_ADDON_SOURCES :=                                             \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SOURCES,                                       \
            $(PATH_OF_ADDON)/libs                                              \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_SOURCES +=                                             \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SOURCES,                                       \
            $(PATH_OF_ADDON)/src                                               \
        )                                                                      \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON_TEMPLATE_LIBRARIES
#   A function that takes the path of an addon and recursively creates a list 
#   of all related libraries and frameworks using the standard ofxAddonTemplate
#   structure.
#   
#   When this function finishes, a well-ordered list of sources for
#   the given addon is available in the following variables:
#   
#
#   forthcoming
#   TODO: should PARSED_ADDON_LIBRARY_SEARCH_PATHS be inferred from the 
#   final list of PARSED_ADDON_SHARED_LIBRARIES_FULL_PATHS and
#   PARSED_ADDON_STATIC_LIBRARIES_FULL_PATHS
#       
################################################################################

define FUNC_PARSE_ADDON_TEMPLATE_LIBRARIES
                                                                               \
    $(eval PATH_OF_ADDON:=$(strip $1))                                         \
                                                                               \
    $(eval PARSED_ADDON_FRAMEWORKS_FULL_PATHS:=                                \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_LIBRARIES_WITH_TYPE_AND_NAME_PATTERN,          \
            $(PATH_OF_ADDON)/libs/*/lib/$(ABI_LIB_SUBPATH),                    \
            $(FIND_TYPE_DIRECTORY),                                            \
            *.framework                                                        \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_LIBRARY_SEARCH_PATHS:=                                 \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_SEARCH_PATHS,                                  \
            $(PATH_OF_ADDON)/libs/*/lib/$(ABI_LIB_SUBPATH),                    \
            $(FIND_TYPE_DIRECTORY)                                             \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_SHARED_LIBRARIES_FULL_PATHS:=                          \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_LIBRARIES_WITH_TYPE_AND_NAME_PATTERN,          \
            $(PATH_OF_ADDON)/libs/*/lib/$(ABI_LIB_SUBPATH),                    \
            $(FIND_TYPE_FILE),                                                 \
            $(PLATFORM_LIBRARY_PREFIX)*.$(PLATFORM_SHARED_LIBRARY_EXTENSION),  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PARSED_ADDON_STATIC_LIBRARIES_FULL_PATHS:=                          \
        $(call                                                                 \
            FUNC_RECURSIVE_FIND_LIBRARIES_WITH_TYPE_AND_NAME_PATTERN,          \
            $(PATH_OF_ADDON)/libs/*/lib/$(ABI_LIB_SUBPATH),                    \
            $(FIND_TYPE_FILE),                                                 \
            $(PLATFORM_LIBRARY_PREFIX)*.$(PLATFORM_STATIC_LIBRARY_EXTENSION)   \
        )                                                                      \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_INSTALL_ADDON
#   A function that is called when a required addon is not found.
#
#   TODO: In the future this function might attempt to install the missing 
#   addon. For now, it simply gives helpful suggestions on how to fix the
#   problem, why the problem might have happened, and then it stops compilation.
#       
################################################################################

define FUNC_INSTALL_ADDON
    $(eval THIS_ADDON:=$(strip $1)) \
    $(warning An addon called [$(THIS_ADDON)] is required for this project     \
        but was not found!)                                                    \
    $(warning Where was it required?:)                                         \
    $(eval F:=$(PATH_OF_PLATFORM_MAKEFILES)/config.$(PLATFORM_LIB_SUBPATH).$(PLATFORM_VARIANT).mk)\
    $(warning --> Did the $(F) file list it?)                                  \
    $(eval F:=$(PATH_OF_ADDONS)/THE_DEPENDENT_ADDON/addon_config.mk)           \
    $(warning --> Did another addon list it as a dependency in its $(F) file?) \
    $(eval F:=$(PATH_PROJECT_ROOT)/addons.make)                                \
    $(warning --> Your project's $(F) file list it?)                           \
    $(warning )                                                                \
    $(error You must install [$(THIS_ADDON)] in your                           \
        $(PATH_OF_ADDONS) directory or modify                                  \
        your configuration to continue)                                        \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON_CONFIG_MK
#   A function that is parses and evaluates all of the variables present in a
#   given addon's addon_config.mk file.
#
#   All variables present within the addon_config.mk file are available after
#   this function is called for the addon that was last parsed.
#
#   This function pushes GNU Make to do things that it didn't sign up for 30
#   years ago.
#
#   Basic steps:
#
#   1. Read the addon_config.mk file for the addon listed in $(THIS_ADDON)
#   
#   2. Read each line of the addon by converting \n to \t since makefiles 
#   treat \n as spaces.
#   
#   3. Convert spaces to $(ESCAPED_DELIMITER) so the foreach works for each 
#   line instead of each word.
# 
#   4. Convert each $(ESCAPED_DELIMITER) back to a to space inside the loop.
#   
#   5. If the line matches common: or platform: set the $(PROCESS_NEXT) flag to 
#   $(TRUE).
#
#   6. If the line matches %: but it's not common: or platform: set 
#   the $(PROCESS_NEXT) flag to $(FALSE).
#
#   7. If the $(PROCESS_NEXT) is equal to $(TRUE), evaluate the line 
#   ($(eval ...)) the line to put the variable in the makefile space.
#   
#   8. Finally, throw an error if the addon listed itself as a dependency.
#
################################################################################

define FUNC_PARSE_ADDON_CONFIG_MK
                                                                               \
    $(eval THIS_ADDON:=$(strip $1))                                            \
    $(eval PATH_OF_ADDON:=$(addprefix $(PATH_OF_ADDONS)/,$(THIS_ADDON)))       \
                                                                               \
    $(eval ADDON_DEPENDENCIES:=)                                               \
    $(eval ADDON_DEPENDENCIES_ESCAPED_STRING:=)                                \
                                                                               \
    $(eval ADDON_HEADER_SEARCH_PATHS:=)                                        \
    $(eval ADDON_LIBRARY_SEARCH_PATHS:=)                                       \
    $(eval ADDON_FRAMEWORK_SEARCH_PATHS:=)                                     \
                                                                               \
    $(eval ADDON_SOURCES:=)                                                    \
                                                                               \
    $(eval ADDON_STATIC_LIBRARIES:=)                                           \
    $(eval ADDON_SHARED_LIBRARIES:=)                                           \
    $(eval ADDON_PKG_CONFIG_LIBRARIES:=)                                       \
    $(eval ADDON_FRAMEWORKS:=)                                                 \
                                                                               \
    $(eval ADDON_DEFINES:=)                                                    \
                                                                               \
    $(eval ADDON_CFLAGS:=)                                                     \
    $(eval ADDON_LDFLAGS:=)                                                    \
                                                                               \
    $(eval ADDON_DATA:=)                                                       \
                                                                               \
    $(eval ADDON_EXCLUSIONS:=)                                                 \
                                                                               \
    $(eval ADDON_EXPORTS:=)                                                    \
                                                                               \
    $(eval PROCESS_NEXT:=$(FALSE))                                             \
                                                                               \
    $(if                                                                       \
        $(filter                                                               \
            $(THIS_ADDON),                                                     \
            $(ALL_INSTALLED_ADDONS)                                            \
        ),                                                                     \
        $(call FUNC_DO_NOTHING),                                               \
        $(call FUNC_INSTALL_ADDON, $(THIS_ADDON))                              \
        $(eval $(ALL_INSTALLED_ADDONS)+=$(THIS_ADDON))                         \
    )                                                                          \
                                                                               \
    $(if                                                                       \
        $(wildcard                                                             \
            $(PATH_OF_ADDON)/addon_config.mk                                   \
        ),                                                                     \
                                                                               \
        $(foreach VAR_LINE,                                                    \
            $(subst $(EMPTY_SPACE),$(ESCAPED_DELIMITER),                       \
                $(shell                                                        \
                    cat $(PATH_OF_ADDON)/addon_config.mk                       \
                    | tr '\n' '\t'                                             \
                )                                                              \
            ),                                                                 \
                                                                               \
            $(eval UNESCAPED_VAR_LINE:=                                        \
                $(strip                                                        \
                    $(subst                                                    \
                        $(ESCAPED_DELIMITER),                                  \
                        $(EMPTY_SPACE),                                        \
                        $(VAR_LINE)                                            \
                    )                                                          \
                )                                                              \
            )                                                                  \
                                                                               \
            $(if                                                               \
                $(filter                                                       \
                    $(PROCESS_NEXT),                                           \
                    $(TRUE)                                                    \
                ),                                                             \
                $(eval $(UNESCAPED_VAR_LINE)),                                 \
                $(call FUNC_DO_NOTHING)                                        \
            )                                                                  \
                                                                               \
            $(if                                                               \
                $(filter                                                       \
                    %:,                                                        \
                    $(UNESCAPED_VAR_LINE)                                      \
                ),                                                             \
                $(if                                                           \
                    $(filter                                                   \
                        common:,                                               \
                        $(UNESCAPED_VAR_LINE)                                  \
                    ),                                                         \
                    $(eval PROCESS_NEXT:=$(TRUE)),                             \
                    $(if                                                       \
                        $(filter                                               \
                            $(ABI_LIB_SUBPATH):,                               \
                            $(UNESCAPED_VAR_LINE)                              \
                        ),                                                     \
                        $(eval PROCESS_NEXT:=$(TRUE)),                         \
                        $(eval PROCESS_NEXT:=$(FALSE))                         \
                    )                                                          \
                )                                                              \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(if                                                                       \
        $(filter                                                               \
            $(THIS_ADDON),                                                     \
            $(ADDON_DEPENDENCIES)                                              \
        ),                                                                     \
        $(error Whhhhoa. $(THIS_ADDON) depends on itself!                      \
            Please check its addon_config.make file                            \
        )                                                                      \
    )                                                                          \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON_CONFIG_MK
#   A function that recursively builds a list of addon dependencies so that the
#   dependencies can be ordered optimally during compilation and linking.
#
#   This function pushes GNU Make to do things that it didn't sign up for 30
#   years ago.
#
#   Basic steps:
#
#       Forthcoming :)
#
################################################################################

define FUNC_BUILD_ADDON_DEPENDENCY_LIST
    $(eval THIS_ADDON:=$(strip $1))                                            \
                                                                               \
    $(call FUNC_PARSE_ADDON_CONFIG_MK,$(THIS_ADDON))                           \
                                                                               \
    $(eval ADDON_DEPENDENCIES:=$(strip $(ADDON_DEPENDENCIES)))                 \
                                                                               \
    $(eval PROJECT_ADDON_DEPENDENCY_STACK:=                                    \
        $(THIS_ADDON) $(PROJECT_ADDON_DEPENDENCY_STACK)                        \
    )                                                                          \
                                                                               \
    $(foreach ADDON_DEPENDENCY,$(ADDON_DEPENDENCIES),                          \
                                                                               \
        $(if                                                                   \
            $(filter                                                           \
                $(ADDON_DEPENDENCY),                                           \
                $(PROJECT_ADDON_DEPENDENCIES)                                  \
            ),                                                                 \
            $(call FUNC_DO_NOTHING),                                           \
            $(call FUNC_BUILD_ADDON_DEPENDENCY_LIST, $(ADDON_DEPENDENCY))      \
        )                                                                      \
                                                                               \
        $(eval PROJECT_ADDON_DEPENDENCIES_PAIRS:=                              \
                $(PROJECT_ADDON_DEPENDENCIES_PAIRS)                            \
                $(firstword $(PROJECT_ADDON_DEPENDENCY_STACK))                 \
                $(ADDON_DEPENDENCY))                                           \
    )                                                                          \
                                                                               \
    $(if                                                                       \
        $(filter                                                               \
            $(firstword $(PROJECT_ADDON_DEPENDENCY_STACK)),                    \
            $(PROJECT_ADDON_DEPENDENCIES)                                      \
        ),                                                                     \
        $(call FUNC_DO_NOTHING),                                               \
        $(eval PROJECT_ADDON_DEPENDENCIES:=                                    \
            $(firstword $(PROJECT_ADDON_DEPENDENCY_STACK))                     \
            $(PROJECT_ADDON_DEPENDENCIES)                                      \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval PROJECT_ADDON_DEPENDENCY_STACK:=                                    \
        $(wordlist 2,                                                          \
            $(words                                                            \
                $(PROJECT_ADDON_DEPENDENCY_STACK)                              \
            ),                                                                 \
            $(PROJECT_ADDON_DEPENDENCY_STACK)                                  \
        )                                                                      \
    )                                                                          \
                                                                               \

endef

################################################################################
# FUNCTION FUNC_PARSE_ADDON
#   A function that can parse a single addon.  This is achieved by calling:
#   FUNC_PARSE_ADDON_CONFIG_MK and processing the results.  (Note:
#   FUNC_PARSE_ADDON_CONFIG_MK is also called previously when determining 
#   the dependency hierarchy.)
#
#   The following variables for each addon are available after execution.  The
#   should be aggregated and passed to the compile make files.
#
#   ORDERED_ADDON_HEADER_SEARCH_PATHS
#       This variable is created by first filtering out any of the paths
#       explicitly listed in the addon_config.mk file 
#       (i.e. ADDON_HEADER_SEARCH_PATHS) from the paths that were
#       automatically discovered by traversing the standard addon template.
#       Those ADDON_HEADER_SEARCH_PATHS are then PREPENDED to the final list,
#       effectively giving explicitly listed paths priority.  All of the
#       paths are then subjected to the ADDON_EXCLUSIONS filter, which removes
#       any and all paths matching any of the ADDON_EXCLUSIONS listed in the
#       addon_config.mk file.
#
#   ORDERED_ADDON_SOURCES
#       This variable is created in using the same pattern as 
#       ORDERED_ADDON_HEADER_SEARCH_PATHS above.
#
#   ORDERED_ADDON_FRAMEWORKS_FULL_PATHS
#       This variable is the full path of each discovered framework (i.e. any 
#       directory in the addon template ending with *.framework).  These full
#       paths are not used directly during compilation, but we derive other 
#       variables from them, including ORDERED_ADDON_FRAMEWORK_SEARCH_PATHS and 
#       ORDERED_ADDON_FRAMEWORKS.  Like the other variables, they are subjected
#       to the same ADDON_EXCLUSIONS filter.  Finally this variable will be used
#       to export these non-system frameworks to the application bundle during 
#       compilation.
#   
#   ORDERED_ADDON_FRAMEWORK_SEARCH_PATHS
#       These paths will eventually be prepended with -F during compilation.
#       It is prepared in a similar way to ORDERED_ADDON_HEADER_SEARCH_PATHS.
#
#   ORDERED_ADDON_FRAMEWORKS
#       This variable is a list of all required frameworks.  These can be listed
#       in the addon_config.mk file or discovered using the standard addon
#       template.  To create this variable, we first extract the framework 
#       directory name, then extract the directory's base name, which is the 
#       name we use to request the framework.  Next, we remove any of the 
#       ADDON_FRAMEWORKS listed in the config_addon.mk file and prepend the
#       ADDON_FRAMEWORKS to the list, giving them priority.
#
#   ORDERED_ADDON_SHARED_LIBRARIES_FULL_PATHS
#       This variable is the full path of each discovered shared lib (i.e. any 
#       directory in the addon template ending with 
#       *.$(PLATFORM_SHARED_LIBRARY_EXTENSION)).  These full paths are not used 
#       directly during compilation, but we derive other variables from them.
#       Like the other variables, they are subjected to the same 
#       ADDON_EXCLUSIONS filter.  Finally this variable will be used
#       to export these non-system shared libs to the application bundle or 
#       data/libs folder during compilation.
#
#   ORDERED_ADDON_LIBRARY_SEARCH_PATHS
#       This variable lists all of the library search paths.  It is prepared
#       in a similar way to ORDERED_ADDON_HEADER_SEARCH_PATHS.  These search
#       paths used by the compiler to find and link both shared and static 
#       libraries.  They will eventually be prepended with -L during linking.
#
#   ORDERED_ADDON_SHARED_LIBRARIES
#       This variable lists all of the shared libraries.  It is prepared
#       in a similar way to ORDERED_ADDON_HEADER_SEARCH_PATHS.  The library 
#       names will be prepended with -l during linking.  The standard linker 
#       naming rules apply.
#
#   ORDERED_ADDON_STATIC_LIBRARIES
#       This variable lists all of the shared libraries.  It is prepared
#       in a similar way to ORDERED_ADDON_HEADER_SEARCH_PATHS.
#       TODO: the syntax for this is inconsistent with pkg-config and 
#       shared libraries.  Static libraries require full paths and are not
#       linked with -l and -L.
#
################################################################################

define FUNC_PARSE_ADDON 
                                                                               \
    $(eval THIS_ADDON:=$(strip $1))                                            \
                                                                               \
    $(eval PATH_OF_ADDON:=$(addprefix $(PATH_OF_ADDONS)/,$(THIS_ADDON)))       \
                                                                               \
    $(call FUNC_PARSE_ADDON_CONFIG_MK,$(THIS_ADDON))                           \
                                                                               \
    $(eval ADDON_HEADER_SEARCH_PATHS:=$(strip $(ADDON_HEADER_SEARCH_PATHS)))   \
                                                                               \
    $(eval ADDON_EXCLUSIONS:=$(strip $(ADDON_EXCLUSIONS)))                     \
                                                                               \
    $(call                                                                     \
        FUNC_PARSE_ADDON_TEMPLATE_HEADER_SEARCH_PATHS,                         \
        $(PATH_OF_ADDON)                                                       \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_HEADER_SEARCH_PATHS:=                                 \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(ADDON_HEADER_SEARCH_PATHS)                                       \
            $(filter-out                                                       \
                $(ADDON_HEADER_SEARCH_PATHS),                                  \
                $(PARSED_ADDON_HEADER_SEARCH_PATHS)                            \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(call                                                                     \
        FUNC_PARSE_ADDON_TEMPLATE_SOURCES,                                     \
        $(PATH_OF_ADDON)                                                       \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_SOURCES:=                                             \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(ADDON_SOURCES)                                                   \
            $(filter-out                                                       \
                $(ADDON_SOURCES),                                              \
                $(PARSED_ADDON_SOURCES)                                        \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(call                                                                     \
        FUNC_PARSE_ADDON_TEMPLATE_LIBRARIES,                                   \
        $(PATH_OF_ADDON)                                                       \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_FRAMEWORKS_FULL_PATHS :=                              \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(PARSED_ADDON_FRAMEWORKS_FULL_PATHS)                              \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_FRAMEWORK_SEARCH_PATHS :=                             \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(ADDON_FRAMEWORK_SEARCH_PATHS)                                    \
            $(filter-out                                                       \
                $(ADDON_FRAMEWORK_SEARCH_PATHS),                               \
                $(dir                                                          \
                    $(ORDERED_ADDON_FRAMEWORKS_FULL_PATHS)                     \
                )                                                              \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_FRAMEWORKS :=                                         \
        $(ADDON_FRAMEWORKS)                                                    \
        $(filter-out                                                           \
            $(ADDON_FRAMEWORKS),                                               \
            $(basename                                                         \
                $(notdir                                                       \
                    $(ORDERED_ADDON_FRAMEWORKS_FULL_PATHS)                     \
                )                                                              \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_LIBRARY_SEARCH_PATHS:=                                \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(ADDON_LIBRARY_SEARCH_PATHS)                                      \
            $(filter-out                                                       \
                $(ADDON_LIBRARY_SEARCH_PATHS),                                 \
                $(PARSED_ADDON_LIBRARY_SEARCH_PATHS)                           \
            )                                                                  \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_SHARED_LIBRARIES_FULL_PATHS:=                         \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(PARSED_ADDON_SHARED_LIBRARIES_FULL_PATHS)                        \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_SHARED_LIBRARIES:=                                    \
        $(ADDON_SHARED_LIBRARIES)                                              \
            $(filter-out                                                       \
                $(ADDON_SHARED_LIBRARIES),                                     \
                $(patsubst $(PLATFORM_LIBRARY_PREFIX)%,%,                      \
                    $(basename                                                 \
                        $(notdir                                               \
                            $(filter-out                                       \
                                $(ADDON_EXCLUSIONS),                           \
                                $(ORDERED_ADDON_SHARED_LIBRARIES_FULL_PATHS)   \
                            )                                                  \
                        )                                                      \
                    )                                                          \
                )                                                              \
            )                                                                  \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_STATIC_LIBRARIES_FULL_PATHS:=                         \
        $(filter-out                                                           \
            $(ADDON_EXCLUSIONS),                                               \
            $(PARSED_ADDON_STATIC_LIBRARIES_FULL_PATHS)                        \
        )                                                                      \
    )                                                                          \
                                                                               \
    $(eval ORDERED_ADDON_STATIC_LIBRARIES:=                                    \
        $(ADDON_STATIC_LIBRARIES)                                              \
            $(filter-out                                                       \
                $(ADDON_STATIC_LIBRARIES),                                     \
                $(patsubst $(PLATFORM_LIBRARY_PREFIX)%,%,                      \
                    $(basename                                                 \
                        $(notdir                                               \
                            $(filter-out                                       \
                                $(ADDON_EXCLUSIONS),                           \
                                $(ORDERED_ADDON_STATIC_LIBRARIES_FULL_PATHS)   \
                            )                                                  \
                        )                                                      \
                    )                                                          \
                )                                                              \
            )                                                                  \
    )                                                                          \

endef

################################################################################
# ADDON CONFIGURATION
################################################################################
# In this section, we check and see what addons are requested and make an 
# attempt to parse them and prepare them for compilation.  Addons should follow
# the template located here:
# 
#   https://github.com/openFrameworks/ofxAddonTemplate
#
# Files that are included in this standardized structure will be included 
# automatically with this makefile.  Files, assets, etc that do not fit into 
# the standard template should define an addon_config.make file (see the 
# ofxAddonTemplate repository above for more information) to further define
# addon-specific variables, etc.  Further documentation is in the example
# addon_config.make file.
#
# Addons will be compiled for a given project IF an addons.make file listing 
# the requested addons is defined OR the platform-specific configuration file
# has set the PLATFORM_REQUIRED_ADDONS variable.  In either case, the requested
# addons will be validated against the addons located in the PATH_OF_ADDONS 
# folder.
#
################################################################################

B_PROCESS_ADDONS = $(FALSE)

ifdef PLATFORM_REQUIRED_ADDONS
    B_PROCESS_ADDONS = $(TRUE)
endif

ifeq ($(findstring addons.make,$(wildcard $(PATH_PROJECT_ROOT)/*.make)),addons.make)
    B_PROCESS_ADDONS = $(TRUE)
endif

ifeq ($(B_PROCESS_ADDONS),$(TRUE))

################################################################################
# VALIDATE REQUESTED ADDONS ####################################################
################################################################################

################################################################################
# ALL_INSTALLED_ADDONS
#   Create a list of every addon installed in the PATH_OF_ADDONS directory.
#   Remove all paths to leave us with a list of addon names.
################################################################################

    ALL_INSTALLED_ADDONS :=                                                    \
        $(subst $(PATH_OF_ADDONS)/,,$(wildcard $(PATH_OF_ADDONS)/*))

################################################################################
# ALL_REQUESTED_PROJECT_ADDONS (immediately assigned)
#   Create a list of all addons requested in the addons.make file.
#
# Steps:
#   1. Use cat to dump the contents of the addons.make file
#
#       cat $(PATH_PROJECT_ROOT)/addons.make 2> /dev/null \ ...
#
#   2. Use sed to strip out all comments beginning with #
#       (NOTE: to escape $ in make, you must use \#)
#
#      | sed 's/[ ]*\#.*//g' \
#
#   3. Use sed to remove any empty lines 
#       (NOTE: to escape $ in make you must use $$)
#
#       | sed '/^$$/d' \
#
#   TODO: in the future, this function might parse addons.make for a specific
#   addon revision, respository, etc.
#
################################################################################

    ALL_REQUESTED_PROJECT_ADDONS:=                                             \
        $(shell                                                                \
            cat $(PATH_PROJECT_ROOT)/addons.make 2> /dev/null                  \
            | sed 's/[ ]*\#.*//g'                                              \
            | sed '/^$$/d'                                                     \
        )

################################################################################
# PLATFORM_REQUIRED_WITHOUT_ALL_REQUESTED_PROJECT_ADDONS (immediately assigned)
#   Remove any ALL_REQUESTED_PROJECT_ADDONS from the PLATFORM_REQUIRED_ADDONS
#   because we assume that the user is attempting to intentionally reorder them 
#   based on the project's needs.
################################################################################

    PLATFORM_REQUIRED_WITHOUT_ALL_REQUESTED_PROJECT_ADDONS:=                   \
        $(filter-out                                                           \
            $(ALL_REQUESTED_PROJECT_ADDONS),                                   \
            $(PLATFORM_REQUIRED_ADDONS)                                        \
        )

################################################################################
# ALL_REQUESTED_ADDONS (immediately assigned)
#   Create a final list of requested addons for this project.  This list now
#   includes all of the PLATFORM_REQUIRED_ADDONS (MINUS any that were in
#   addons.make) PLUS all of the addons from addons.make.
################################################################################

    ALL_REQUESTED_ADDONS:=                                                     \
        $(PLATFORM_REQUIRED_WITHOUT_ALL_REQUESTED_PROJECT_ADDONS)              \
        $(ALL_REQUESTED_PROJECT_ADDONS)

################################################################################
# REQUESTED_PROJECT_ADDONS (immediately assigned)
#   Add platform required addons from the platform-specific configuration file 
#   (if needed) FIRST, so that they are always linked first.  This list will
#   have the duplicates removed, while preserving order.  See the 
#   FUNC_REMOVE_DUPLICATES_PRESERVE_ORDER for more info.
################################################################################

    REQUESTED_PROJECT_ADDONS:=                                                 \
        $(call FUNC_REMOVE_DUPLICATES_PRESERVE_ORDER,                          \
            $(ALL_REQUESTED_ADDONS)                                            \
        )

################################################################################
# VALID_REQUESTED_PROJECT_ADDONS (immediately assigned)
#   Compare the list of addons that we have requested to those that are
#   located in the PATH_OF_ADDONS folder listed in ALL_INSTALLED_ADDONS
################################################################################

    VALID_REQUESTED_PROJECT_ADDONS:=                                           \
        $(filter                                                               \
            $(REQUESTED_PROJECT_ADDONS),                                       \
            $(ALL_INSTALLED_ADDONS)                                            \
        )

################################################################################
# INVALID_REQUESTED_PROJECT_ADDONS (immediately assigned)
#   Compare the list of addons that we have requested to the those that are
#   located in the PATH_OF_ADDONS folder listed in ALL_INSTALLED_ADDONS
#
#   If any invalid addons are found, we list them.
#
#   We list the invalid files using $(warning ...) because using $(error ...)
#   immediate stops the make file (which means we won't get a full list of 
#   missing addons).  After listing the files, we conclude with an $(error ...) 
#   causing a full stop.
#
################################################################################

    INVALID_REQUESTED_PROJECT_ADDONS:=                                         \
        $(filter-out                                                           \
            $(VALID_REQUESTED_PROJECT_ADDONS),                                 \
            $(REQUESTED_PROJECT_ADDONS)                                        \
        )

    $(foreach ADDON_TO_CHECK,$(INVALID_REQUESTED_PROJECT_ADDONS),              \
        $(call                                                                 \
            FUNC_INSTALL_ADDON,                                                \
            $(ADDON_TO_CHECK)                                                  \
        )                                                                      \
    )                                                                          \

################################################################################
# PROJECT_ADDONS (immediately assigned)
#   PROJECT_ADDONS is a list of the addons that will be compiled for this
#   project.  Theses addon directories will be parsed and compiled.
#   The addons listed in PROEJCT_ADDONS include ONLY the addons listed in 
#   the project's addons.make file and the relevant platform-specific config
#   file (e.g. config.osx.defaul.mk).  This list DOES NOT include the 
#   dependencies defined in addon_config.mk files.  Those dependecnes will be 
#   processsed and added below.
################################################################################

    PROJECT_ADDONS:=$(REQUESTED_PROJECT_ADDONS)

################################################################################
# PROCESS PROJECT ADDONS IF THERE ARE ANY
################################################################################
    ifneq ($(PROJECT_ADDONS),)

        # a list of all dependencies, unordered, listed once    
        PROJECT_ADDON_DEPENDENCIES:=
        # a list of all dependency pairs
        PROJECT_ADDON_DEPENDENCIES_PAIRS:=
        # a variable to keep track of the recursive stack
        PROJECT_ADDON_DEPENDENCY_STACK:=

        $(foreach ADDON_TO_CHECK,$(PROJECT_ADDONS),                            \
            $(call                                                             \
                FUNC_BUILD_ADDON_DEPENDENCY_LIST,                              \
                $(ADDON_TO_CHECK)                                              \
            )                                                                  \
        )


################################################################################
# PROJECT_ADDON_DEPENDENCIES_ORDERED (immediately assigned)
#   Takes a list of addon / depency pairs and does a topological sort using 
#   `tsort`.  The format required by `tsort` is: 
#
#       ADDON_A ADDON_A_REQUIREMENT ADDON_B ADDON_B_REQUIREMENT ... etc.
#
#   Example: To represent a series of relationships like this
#
#       ADDON_A requires ADDON_B
#       ADDON_B requires ADDON_C
#       ADDON_C requires both ADDON_D AND ADDON_E
#   
#   We would create a list that looks like this:
#       
#       ADDON_A ADDON_B ADDON_B ADDON_C ADDON_C ADDON_D ADDON_C ADDON_E
#
#   Thus, when this list of dependecies is sorted with `tsort`, we will arrive 
#   at a unique list of addons sorted by how much other addons depend upon it.
#   This will in effect, allow us to compile our "base" addons earliest.  For
#   reference, the tsort output from the list above will be:
#
#       ADDON_A
#       ADDON_B
#       ADDON_C
#       ADDON_E
#       ADDON_D
#
#   `tsort` can handle repeated pairs and an even-numbered, white-space-sperated 
#   list of addon names is required.
#
#   From the pespective of the compiler, `tsort` will output a reversed list 
#   (i.e. the least-depended-upon addon is first), so in order to get it into
#   our actual compilation order, we reverse the sorted list using:
#   
#       tail -r
#   
#   Finally, in order to bring it back into `make` for processing, we swap 
#   all `\n` characters for ` ` spaces.  This space-seperated list can be 
#   iterated by make's `foreach` command.
#
################################################################################

        PROJECT_ADDON_DEPENDENCIES_ORDERED :=                                  \
            $(shell                                                            \
                echo "$(PROJECT_ADDON_DEPENDENCIES_PAIRS)"                     \
                | tsort                                                        \
                | tail -r                                                      \
                | tr '\n' ' '                                                  \
            )

################################################################################
# ADDITIONAL_DEPENDENCIES (immediately assigned)
#   There are some dependencies that will not be included in the `tsort` list
#   because they are "independent".  Of course the project requires them 
#   (because they were listed in a platform-specific config file or 
#   addons.make).  After determining which addons we need to add to our final
#   list, we add those ADDITIONAL_DEPENDENCIES to our 
#   PROJECT_ADDON_DEPENDENCIES_ORDERED list.
#
################################################################################

        ADDITIONAL_DEPENDENCIES :=                                             \
            $(filter-out                                                       \
                $(PROJECT_ADDON_DEPENDENCIES_ORDERED),                         \
                $(PROJECT_ADDON_DEPENDENCIES)                                  \
            )

        PROJECT_ADDON_DEPENDENCIES_ORDERED += $(ADDITIONAL_DEPENDENCIES)



################################################################################
#   Finally we iterate through each of addons listed in the ordered set
#   (PROJECT_ADDON_DEPENDENCIES_ORDERED) and extract all of their compilation
#   information using FUNC_PARSE_ADDON.  By parsing each addon in order, we 
#   are assured that each addon is parsed in the order required by its 
#   addon_config.mk file.
#
################################################################################
        PROJECT_ADDONS_HEADER_SEARCH_PATHS :=
        PROJECT_ADDONS_SOURCES :=
        PROJECT_ADDONS_FRAMEWORKS_FULL_PATHS :=
        PROJECT_ADDONS_FRAMEWORK_SEARCH_PATHS :=
        PROJECT_ADDONS_FRAMEWORKS :=
        PROJECT_ADDONS_LIBRARY_SEARCH_PATHS :=
        PROJECT_ADDONS_SHARED_LIBRARIES_FULL_PATHS :=
        PROJECT_ADDONS_SHARED_LIBRARIES :=
        PROJECT_ADDONS_STATIC_LIBRARIES_FULL_PATHS :=
        PROJECT_ADDONS_STATIC_LIBRARIES :=

        PROJECT_ADDONS_PKG_CONFIG_LIBRARIES :=

        PROJECT_ADDONS_DEFINES :=
        PROJECT_ADDONS_CFLAGS :=
        PROJECT_ADDONS_LDFLAGS :=
        PROJECT_ADDONS_DATA :=
        PROJECT_ADDONS_EXPORTS :=

        $(foreach ADDON_TO_PARSE,                                              \
            $(PROJECT_ADDON_DEPENDENCIES_ORDERED),                             \
            $(call FUNC_PARSE_ADDON,$(ADDON_TO_PARSE))                         \
                                                                               \
            $(eval PROJECT_ADDONS_HEADER_SEARCH_PATHS +=                       \
                $(ORDERED_ADDON_HEADER_SEARCH_PATHS))                          \
                                                                               \
            $(eval PROJECT_ADDONS_SOURCES +=                                   \
                $(ORDERED_ADDON_SOURCES))                                      \
                                                                               \
            $(eval PROJECT_ADDONS_FRAMEWORKS_FULL_PATHS +=                     \
                $(ORDERED_ADDON_FRAMEWORKS_FULL_PATHS))                        \
                                                                               \
            $(eval PROJECT_ADDONS_FRAMEWORK_SEARCH_PATHS +=                    \
                $(ORDERED_ADDON_FRAMEWORK_SEARCH_PATHS))                       \
                                                                               \
            $(eval PROJECT_ADDONS_FRAMEWORKS +=                                \
                $(ORDERED_ADDON_FRAMEWORKS))                                   \
                                                                               \
            $(eval PROJECT_ADDONS_LIBRARY_SEARCH_PATHS +=                      \
                $(ORDERED_ADDON_LIBRARY_SEARCH_PATHS))                         \
                                                                               \
            $(eval PROJECT_ADDONS_SHARED_LIBRARIES_FULL_PATHS +=               \
                $(ORDERED_ADDON_SHARED_LIBRARIES_FULL_PATHS))                  \
                                                                               \
            $(eval PROJECT_ADDONS_SHARED_LIBRARIES +=                          \
                $(ORDERED_ADDON_SHARED_LIBRARIES))                             \
                                                                               \
            $(eval PROJECT_ADDONS_STATIC_LIBRARIES_FULL_PATHS +=               \
                $(ORDERED_ADDON_STATIC_LIBRARIES_FULL_PATHS))                  \
                                                                               \
            $(eval PROJECT_ADDONS_STATIC_LIBRARIES +=                          \
                $(ORDERED_ADDON_STATIC_LIBRARIES))                             \
                                                                               \
            $(eval PROJECT_ADDONS_PKG_CONFIG_LIBRARIES +=                      \
                $(ADDON_PKG_CONFIG_LIBRARIES))                                 \
                                                                               \
            $(eval PROJECT_ADDONS_DEFINES +=                                   \
                $(ADDON_TO_PARSE)                                              \
                $(ADDON_DEFINES))                                              \
                                                                               \
            $(eval PROJECT_ADDONS_DATA +=                                      \
                $(ADDON_DATA))                                                 \
                                                                               \
            $(eval PROJECT_ADDONS_CFLAGS +=                                    \
                $(ADDON_CFLAGS))                                               \
                                                                               \
            $(eval PROJECT_ADDONS_LDFLAGS +=                                   \
                $(ADDON_LDFLAGS))                                              \
                                                                               \
            $(eval PROJECT_ADDONS_EXPORTS +=                                   \
                $(ORDERED_ADDON_FRAMEWORKS_FULL_PATHS)                        \
                $(ORDERED_ADDONS_SHARED_LIBRARIES_FULL_PATHS))                 \
    )

        
    # $(info ---ORDERED_ADDON_HEADER_SEARCH_PATHS---)                                        \
    # $(foreach v, $(ORDERED_ADDON_HEADER_SEARCH_PATHS),$(info $(v)))                        \
    # $(info ---ORDERED_ADDON_SOURCES---)                                        \
    # $(foreach v, $(ORDERED_ADDON_SOURCES),$(info $(v)))                        \

    endif
endif

########################################################################
#  DEBUGGING
########################################################################
# print debug information if so instructed
    $(info ---PROJECT_ADDONS_HEADER_SEARCH_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_HEADER_SEARCH_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_SOURCES---)
    $(foreach v, $(PROJECT_ADDONS_SOURCES),$(info $(v)))

    $(info ---PROJECT_ADDONS_FRAMEWORKS_FULL_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_FRAMEWORKS_FULL_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_FRAMEWORK_SEARCH_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_FRAMEWORK_SEARCH_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_FRAMEWORKS---)
    $(foreach v, $(PROJECT_ADDONS_FRAMEWORKS),$(info $(v)))

    $(info ---PROJECT_ADDONS_LIBRARY_SEARCH_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_LIBRARY_SEARCH_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_SHARED_LIBRARIES_FULL_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_SHARED_LIBRARIES_FULL_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_SHARED_LIBRARIES---)
    $(foreach v, $(PROJECT_ADDONS_SHARED_LIBRARIES),$(info $(v)))

    $(info ---PROJECT_ADDONS_STATIC_LIBRARIES_FULL_PATHS---)
    $(foreach v, $(PROJECT_ADDONS_STATIC_LIBRARIES_FULL_PATHS),$(info $(v)))

    $(info ---PROJECT_ADDONS_STATIC_LIBRARIES---)
    $(foreach v, $(PROJECT_ADDONS_STATIC_LIBRARIES),$(info $(v)))

    $(info ---PROJECT_ADDONS_PKG_CONFIG_LIBRARIES---)
    $(foreach v, $(PROJECT_ADDONS_PKG_CONFIG_LIBRARIES),$(info $(v)))

    $(info ---PROJECT_ADDONS_DEFINES---)
    $(foreach v, $(PROJECT_ADDONS_DEFINES),$(info $(v)))

    $(info ---PROJECT_ADDONS_DATA---)
    $(foreach v, $(PROJECT_ADDONS_DATA),$(info $(v)))

    $(info ---PROJECT_ADDONS_CFLAGS---)
    $(foreach v, $(PROJECT_ADDONS_CFLAGS),$(info $(v)))

    $(info ---PROJECT_ADDONS_LDFLAGS---)
    $(foreach v, $(PROJECT_ADDONS_LDFLAGS),$(info $(v)))

    $(info ---PROJECT_ADDONS_EXPORTS---)
    $(foreach v, $(PROJECT_ADDONS_EXPORTS),$(info $(v)))

ifdef 1
    # $(info ---PROJECT_ADDONS_INCLUDES---)
    # $(foreach v, $(PROJECT_ADDONS_INCLUDES),$(info $(v)))
    # $(info ---PROJECT_ADDONS_EXCLUSIONS---)
    # $(foreach v, $(PROJECT_ADDONS_EXCLUSIONS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_FRAMEWORKS---)
    # $(foreach v, $(PROJECT_ADDONS_FRAMEWORKS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_SOURCE_FILES---)
    # $(foreach v, $(PROJECT_ADDONS_SOURCE_FILES),$(info $(v)))
    # $(info ---PROJECT_ADDONS_LIBS---)
    # $(foreach v, $(PROJECT_ADDONS_LIBS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_OBJFILES---)
    # $(foreach v, $(PROJECT_ADDONS_OBJFILES),$(info $(v)))
    # $(info ---PROJECT_ADDONS_BASE_CFLAGS---)
    # $(foreach v, $(PROJECT_ADDONS_BASE_CFLAGS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_DEFINES_CFLAGS---)
    # $(foreach v, $(PROJECT_ADDONS_DEFINES_CFLAGS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_INCLUDES_CFLAGS---)
    # $(foreach v, $(PROJECT_ADDONS_INCLUDES_CFLAGS),$(info $(v)))
    # $(info ---PROJECT_ADDONS_LDFLAGS---)
    # $(foreach v, $(PROJECT_ADDONS_LDFLAGS),$(info $(v)))
endif