cmake_minimum_required(VERSION 2.8)

set(LEVEL_CODENAME "scene100")
set(LEVEL_LONGNAME "Leaving Earth")

if(NOT DEFINED COLOBOT_INSTALL_DATA_DIR)
        set(COLOBOT_INSTALL_DATA_DIR ${CMAKE_INSTALL_PREFIX}/share/games/colobot CACHE PATH "Colobot shared data directory")
endif()

set(LEVEL_INSTALL_DATA_DIR ${COLOBOT_INSTALL_DATA_DIR}/${LEVEL_CODENAME})

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
