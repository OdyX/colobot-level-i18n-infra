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

file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/levels/*.txt")
list(SORT levelfiles)
file(GLOB helpfiles "${CMAKE_CURRENT_SOURCE_DIR}/help/*.txt")
list(SORT helpfiles)

#### STEP 1 # Extract strings from level files, create .xml and .part-xhtml files out of them
foreach(levelfile ${levelfiles})
	get_filename_component(_levelfile_we ${levelfile} NAME_WE)
	get_filename_component(_levelfile    ${levelfile} NAME)

	### STEP 3 # Inject translations in levels
	set(_levels_i18n_target "levels_i18n")
	if(PO4A)
		add_custom_command(OUTPUT ${_levels_i18n_target}/${_levelfile}
			COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}
			COMMAND ./scripts/03_inject_translations.sh ${levelfile} ${CMAKE_CURRENT_BINARY_DIR}/levels/${_levelfile_we} > ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}/${_levelfile}
			DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/po4a-ran
			WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			COMMENT "Inject translation in ${_levelfile}"
			)
		add_custom_target(inject_translation_${_levelfile_we} ALL DEPENDS ${_levels_i18n_target}/${_levelfile})
		install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${_levels_i18n_target}/${_levelfile}
			DESTINATION ${LEVEL_INSTALL_DATA_DIR})
	endif()
endforeach()

#### STEP 1 # Create po4a.cfg file out of the list of files
add_custom_command(OUTPUT po4a.cfg
	COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/01_create_po4a_file.sh ${CMAKE_CURRENT_SOURCE_DIR} po levels help > ${CMAKE_CURRENT_BINARY_DIR}/po4a.cfg
		COMMENT "Create po4a file"
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)

if(PO4A)
	#### STEP 2 # Run po4a
	add_custom_command(OUTPUT po4a-ran
			   COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/scripts/02_run_po4a.sh ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/po4a.cfg
			   COMMAND touch po4a-ran
			   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/po4a.cfg
			   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
			   COMMENT "Run po4a to generate the translations out of the xml files")
	add_custom_target(po4a DEPENDS po4a-ran)
else()
	message(WARNING "po4a not found, levels will not get translated")
	file(GLOB levelfiles "${CMAKE_CURRENT_SOURCE_DIR}/levels/*.txt")
	install(FILES ${levelfiles} DESTINATION ${LEVEL_INSTALL_DATA_DIR}/)
endif()
