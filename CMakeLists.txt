cmake_minimum_required(VERSION 2.8)

set(LEVEL_CODENAME "scene100")
set(LEVEL_LONGNAME "Leaving Earth")

project(colobot-level-${LEVEL_CODENAME} NONE)

if(NOT DEFINED COLOBOT_INSTALL_DATA_DIR)
        set(COLOBOT_INSTALL_DATA_DIR ${CMAKE_INSTALL_PREFIX}/share/games/colobot CACHE PATH "Colobot shared data directory")
endif()
set(LEVEL_INSTALL_DATA_DIR ${COLOBOT_INSTALL_DATA_DIR}/levels/${LEVEL_CODENAME})
message(STATUS "Will install '${LEVEL_LONGNAME}' (${LEVEL_CODENAME}) to ${LEVEL_INSTALL_DATA_DIR}")


#### STEP 1 # Extract strings from level files, create .xml and .part-xhtml files out of them

# Handle translation of level definitions
file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/levels/*.txt")
add_custom_target(extract_strings) # For .xml files
set(extract_strings_catlist "")
foreach(levelfile ${levelfiles})
	get_filename_component(_levelfile_we ${levelfile} NAME_WE)
	add_custom_command(OUTPUT ${_levelfile_we}.xml ${_levelfile_we}.part-xhtml
		COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/01_extract_strings_to_xml.sh ${levelfile} ${_levelfile_we}.xml ${_levelfile_we}.part-xhtml
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Extract strings from ${levelfile}"
		)
	add_custom_target(extract_strings_${_levelfile_we} DEPENDS ${_levelfile_we}.xml)
	add_dependencies(extract_strings extract_strings_${_levelfile_we})

	set(extract_strings_catlist ${extract_strings_catlist} ${_levelfile_we}.part-xhtml)
endforeach()

#### STEP 2 # Create common XHTML file out of .part-xhtml files
add_custom_command(OUTPUT common.xhtml
		COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/02_create_common_xhtml_file.sh ${extract_strings_catlist} > common.xhtml
		DEPENDS ${extract_strings_catlist}
		COMMENT "Create common.xhtml file from partial xhtml files"
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)
add_custom_target(extract_strings_common DEPENDS common.xhtml) # For the common .xhtml file

# Translate translatable material
find_program(PO4A po4a)

if(PO4A)
	set(_levels_i18n_target "levels_i18n")
	add_custom_command(OUTPUT ${_levels_i18n_target}
		COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}
		COMMAND ./scripts/gen_levels_xml.sh ${CMAKE_CURRENT_SOURCE_DIR}/levels/ ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		COMMENT "Inject level translations"
		)
	add_custom_target(translate_levels ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target})
	install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}/
		DESTINATION ${COLOBOT_INSTALL_DATA_DIR}/levels
		PATTERN CMake*.txt EXCLUDE
		PATTERN install_manifest.txt EXCLUDE)
else()
	message(WARNING "po4a not found, levels will not get translated")
	file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/*.txt")
	list(REMOVE_ITEM levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
	install(FILES ${levelfiles} DESTINATION ${COLOBOT_INSTALL_DATA_DIR}/levels/)
endif()
