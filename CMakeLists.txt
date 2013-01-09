cmake_minimum_required(VERSION 2.8)

set(LEVEL_CODENAME "scene100")
set(LEVEL_LONGNAME "Leaving Earth")

project(colobot-level-${LEVEL_CODENAME} NONE)

if(NOT DEFINED COLOBOT_INSTALL_DATA_DIR)
        set(COLOBOT_INSTALL_DATA_DIR ${CMAKE_INSTALL_PREFIX}/share/games/colobot CACHE PATH "Colobot shared data directory")
endif()
set(LEVEL_INSTALL_DATA_DIR ${COLOBOT_INSTALL_DATA_DIR}/levels/${LEVEL_CODENAME})
message(STATUS "Will install '${LEVEL_LONGNAME}' (${LEVEL_CODENAME}) to ${LEVEL_INSTALL_DATA_DIR}")

# Translate translatable material
find_program(PO4A po4a)

#### STEP 1 # Extract strings from level files, create .xml and .part-xhtml files out of them
file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/levels/*.txt")
list(SORT levelfiles)
add_custom_target(extract_strings) # For .xml files
foreach(levelfile ${levelfiles})
	get_filename_component(_levelfile_we ${levelfile} NAME_WE)
	get_filename_component(_levelfile    ${levelfile} NAME)
	add_custom_command(OUTPUT ${_levelfile_we}.xml ${_levelfile_we}.part-xhtml
		COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/01_extract_strings_to_xml.sh ${levelfile} ${_levelfile_we}.xml ${_levelfile_we}.part-xhtml
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		COMMENT "Extract strings from ${levelfile}"
		)
	add_custom_target(extract_strings_${_levelfile_we} DEPENDS ${_levelfile_we}.xml)
	add_dependencies(extract_strings extract_strings_${_levelfile_we})

	set(extract_strings_catlist ${extract_strings_catlist} ${_levelfile_we}.part-xhtml)
	set(extract_strings_po4alist ${extract_strings_po4alist} ${_levelfile_we})

	### STEP 5 # Inject translations in levels
	set(_levels_i18n_target "levels_i18n")
	if(PO4A)
		add_custom_command(OUTPUT ${_levels_i18n_target}/${_levelfile}
			COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}
			COMMAND ./scripts/05_inject_translations.sh ${levelfile} ${CMAKE_CURRENT_BINARY_DIR}/${_levelfile_we} > ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}/${_levelfile}
			DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/po4a-ran
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			COMMENT "Inject translation in ${_levelfile}"
			)
		add_custom_target(inject_translation_${_levelfile_we} ALL DEPENDS ${_levels_i18n_target}/${_levelfile})
		install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}/${_levelfile}
			DESTINATION ${LEVEL_INSTALL_DATA_DIR})
	endif()
endforeach()

#### STEP 2 # Create common XHTML file out of .part-xhtml files
add_custom_command(OUTPUT common.xhtml
		COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/02_create_common_xhtml_file.sh ${extract_strings_catlist} > common.xhtml
		DEPENDS ${extract_strings_catlist}
		COMMENT "Create common.xhtml file from partial xhtml files"
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)
add_custom_target(extract_strings_common DEPENDS common.xhtml) # For the common .xhtml file

#### STEP 3 # Create po4a.cfg file out of the list of files
add_custom_command(OUTPUT po4a.cfg
		COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/03_create_po4a_file.sh ${CMAKE_CURRENT_SOURCE_DIR}/po ${extract_strings_po4alist} > po4a.cfg
		COMMENT "Create po4a file"
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)

if(PO4A)
	### STEP 4 # Update PO
	add_custom_command(OUTPUT update-po-ran
			   COMMAND po4a-gettextize -M UTF-8 -f xhtml -m common.xhtml > ${CMAKE_CURRENT_SOURCE_DIR}/po/level.pot
			   COMMAND touch update-po-ran
			   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/common.xhtml
			   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			   COMMENT "Update level.pot from level's common.xhtml file.")
	add_custom_target(update-po DEPENDS update-po-ran)

	#### STEP 5 # Run po4a
	add_custom_command(OUTPUT po4a-ran
			   COMMAND po4a -v -f po4a.cfg
			   COMMAND touch po4a-ran
			   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/po4a.cfg ${extract_strings_catlist} update-po-ran
			   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			   COMMENT "Run po4a to generate the translations out of the xml files")
	add_custom_target(po4a DEPENDS po4a-ran)
else()
	message(WARNING "po4a not found, levels will not get translated")
	file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/*.txt")
	list(REMOVE_ITEM levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt")
	install(FILES ${levelfiles} DESTINATION ${COLOBOT_INSTALL_DATA_DIR}/levels/)
endif()
