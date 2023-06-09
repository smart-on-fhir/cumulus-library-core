""" tests for study parser against mocks in test_data """
import pathlib
from contextlib import nullcontext as does_not_raise
from unittest import mock

import pytest

from cumulus_library.study_parser import StudyManifestParser, StudyManifestParsingError
from tests.test_data.parser_mock_data import get_mock_toml, mock_manifests


@pytest.mark.parametrize(
    "manifest_path,raises",
    [
        ("test_data/study_valid", does_not_raise()),
        (None, does_not_raise()),
        ("test_data/study_missing_prefix", pytest.raises(StudyManifestParsingError)),
        ("test_data/study_wrong_type", pytest.raises(StudyManifestParsingError)),
        ("", pytest.raises(StudyManifestParsingError)),
        (".", pytest.raises(StudyManifestParsingError)),
    ],
)
def test_load_manifest(manifest_path, raises):
    with raises:
        if manifest_path is not None:
            path = f"{pathlib.Path(__file__).resolve().parents[0]}/{manifest_path}"
        else:
            path = None
        StudyManifestParser(path)


@pytest.mark.parametrize(
    "manifest_key, raises",
    [
        ("valid", does_not_raise()),
        ("valid_empty_arrays", does_not_raise()),
        ("valid_null_arrays", does_not_raise()),
        ("valid_only_prefix", does_not_raise()),
        ("invalid_bad_export_names", pytest.raises(StudyManifestParsingError)),
        ("invalid_none", pytest.raises(TypeError)),
    ],
)
def test_manifest_data(manifest_key, raises):
    with mock.patch(
        "builtins.open", mock.mock_open(read_data=get_mock_toml(manifest_key))
    ):
        with raises:
            if manifest_key == "invalid_none":
                parser = StudyManifestParser()
            else:
                parser = StudyManifestParser("./path")
            expected = mock_manifests[manifest_key]
            assert parser.get_study_prefix() == expected["study_prefix"]
            if "sql_config" in expected.keys():
                if expected["sql_config"]["file_names"] is None:
                    assert parser.get_sql_file_list() == []
                else:
                    assert (
                        parser.get_sql_file_list()
                        == expected["sql_config"]["file_names"]
                    )
            else:
                assert parser.get_sql_file_list() == []
            if "export_config" in expected.keys():
                if expected["export_config"]["export_list"] is None:
                    assert parser.get_export_table_list() == []
                else:
                    assert (
                        parser.get_export_table_list()
                        == expected["export_config"]["export_list"]
                    )
            else:
                assert parser.get_export_table_list() == []


@pytest.mark.parametrize(
    "schema,verbose,query_res,raises",
    [
        ("schema", True, "test__table", does_not_raise()),
        ("schema", False, "test__table", does_not_raise()),
        ("schema", None, "test__table", does_not_raise()),
        (None, True, "test__table", pytest.raises(ValueError)),
        ("schema", None, "test__etl_table", does_not_raise()),
        ("schema", None, "test__nlp_table", does_not_raise()),
        ("schema", None, "test__lib_table", does_not_raise()),
    ],
)
@mock.patch("cumulus_library.helper.query_console_output")
def test_clean_study(mock_output, schema, verbose, query_res, raises):
    with raises:
        mock_cursor = mock.MagicMock()
        mock_cursor.__iter__.return_value = [[query_res]]
        parser = StudyManifestParser("./tests/test_data/study_valid/")
        tables = parser.clean_study(mock_cursor, schema, verbose)
        if query_res != "test__table":
            assert not tables
        else:
            assert tables == [["test__table", "VIEW"]]
        assert mock_output.is_called()


@pytest.mark.parametrize(
    "path,verbose,raises",
    [
        ("./tests/test_data/study_valid/", True, does_not_raise()),
        ("./tests/test_data/study_valid/", False, does_not_raise()),
        ("./tests/test_data/study_valid/", None, does_not_raise()),
        ("./tests/test_data/study_wrong_prefix/", None, pytest.raises(SystemExit)),
        ("./tests/test_data/study_python_valid/", True, does_not_raise()),
        (
            "./tests/test_data/study_python_no_subclass/",
            True,
            pytest.raises(StudyManifestParsingError),
        ),
        ("./tests/test_data/study_invalid_no_dunder/", True, pytest.raises(SystemExit)),
        (
            "./tests/test_data/study_invalid_two_dunder/",
            True,
            pytest.raises(SystemExit),
        ),
        (
            "./tests/test_data/study_invalid_reserved_word/",
            True,
            pytest.raises(SystemExit),
        ),
    ],
)
@mock.patch("cumulus_library.helper.query_console_output")
def test_build_study(mock_output, path, verbose, raises):
    with raises:
        mock_cursor = mock.MagicMock()
        parser = StudyManifestParser(path)
        parser.run_python_builder(mock_cursor, verbose)
        queries = parser.build_study(mock_cursor, verbose)
        if "python" not in path:
            assert queries == [["CREATE TABLE test__table (test int)", "test.sql"]]
            assert mock_output.is_called()


def test_export_study(monkeypatch):
    mock_cursor = mock.MagicMock()
    parser = StudyManifestParser("./tests/test_data/study_valid/")
    monkeypatch.setattr(pathlib, "PosixPath", mock.MagicMock())
    queries = parser.export_study(mock_cursor, "./path")
    assert queries == ["select * from test__table"]
