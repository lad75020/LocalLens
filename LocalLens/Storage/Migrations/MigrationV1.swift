import Foundation

public enum MigrationV1 {
    public static let schemaVersion = 1
    public static let statements: [String] = [
        "PRAGMA journal_mode=WAL;",
        "CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL);",
        "CREATE TABLE IF NOT EXISTS watched_folders (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, bookmark_data BLOB NOT NULL, original_path_hash TEXT NOT NULL, display_path TEXT NOT NULL, is_enabled INTEGER NOT NULL, authorization_state TEXT NOT NULL, last_scan_started_at REAL, last_scan_completed_at REAL, created_at REAL NOT NULL, updated_at REAL NOT NULL);",
        "CREATE TABLE IF NOT EXISTS media_assets (id TEXT PRIMARY KEY, watched_folder_id TEXT NOT NULL, file_identity TEXT NOT NULL, relative_path TEXT NOT NULL, path_hash TEXT NOT NULL, filename TEXT NOT NULL, media_type TEXT NOT NULL, content_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, created_at_file REAL, modified_at_file REAL, indexed_signature TEXT NOT NULL, dimensions TEXT, duration_seconds REAL, page_count INTEGER, thumbnail_state TEXT NOT NULL, index_state TEXT NOT NULL, last_indexed_at REAL, created_at REAL NOT NULL, updated_at REAL NOT NULL);",
        "CREATE INDEX IF NOT EXISTS idx_media_assets_folder ON media_assets(watched_folder_id);",
        "CREATE TABLE IF NOT EXISTS extraction_records (id TEXT PRIMARY KEY, asset_id TEXT NOT NULL, stage TEXT NOT NULL, provider_id TEXT, provider_mode TEXT NOT NULL, status TEXT NOT NULL, safe_summary TEXT, confidence REAL, page_number INTEGER, timestamp_start REAL, timestamp_end REAL, error_category TEXT, created_at REAL NOT NULL, updated_at REAL NOT NULL);",
        "CREATE INDEX IF NOT EXISTS idx_extraction_records_asset ON extraction_records(asset_id);",
        "CREATE TABLE IF NOT EXISTS searchable_chunks (id TEXT PRIMARY KEY, asset_id TEXT NOT NULL, extraction_record_id TEXT, chunk_type TEXT NOT NULL, text TEXT NOT NULL, normalized_text TEXT NOT NULL, embedding_model TEXT, page_number INTEGER, timestamp_start REAL, timestamp_end REAL, confidence REAL, created_at REAL NOT NULL);",
        "CREATE INDEX IF NOT EXISTS idx_searchable_chunks_asset ON searchable_chunks(asset_id);",
        "CREATE VIRTUAL TABLE IF NOT EXISTS searchable_chunks_fts USING fts5(id UNINDEXED, filename, text, labels, transcript, pdf_text);",
        "CREATE TABLE IF NOT EXISTS vector_embeddings (chunk_id TEXT PRIMARY KEY, model_id TEXT NOT NULL, dimensions INTEGER NOT NULL, vector BLOB NOT NULL);",
        "CREATE TABLE IF NOT EXISTS index_jobs (id TEXT PRIMARY KEY, job_type TEXT NOT NULL, watched_folder_id TEXT, asset_id TEXT, priority INTEGER NOT NULL, status TEXT NOT NULL, attempt_count INTEGER NOT NULL, last_error_category TEXT, progress_unit TEXT, progress_completed INTEGER NOT NULL, progress_total INTEGER, created_at REAL NOT NULL, started_at REAL, completed_at REAL);",
        "CREATE INDEX IF NOT EXISTS idx_index_jobs_status_priority ON index_jobs(status, priority DESC, created_at ASC);",
        "CREATE TABLE IF NOT EXISTS index_failures (id TEXT PRIMARY KEY, asset_id TEXT, watched_folder_id TEXT, stage TEXT NOT NULL, category TEXT NOT NULL, retryability TEXT NOT NULL, safe_message TEXT NOT NULL, raw_debug_reference TEXT, created_at REAL NOT NULL, resolved_at REAL);",
        "CREATE INDEX IF NOT EXISTS idx_index_failures_unresolved ON index_failures(resolved_at, created_at);",
        "CREATE TABLE IF NOT EXISTS provider_settings (id TEXT PRIMARY KEY, display_name TEXT NOT NULL, base_url TEXT NOT NULL, is_enabled INTEGER NOT NULL, automatic_indexing_enabled INTEGER NOT NULL, locality TEXT NOT NULL, transport_state TEXT NOT NULL, credential_state TEXT NOT NULL, model_ids_json TEXT NOT NULL, selected_model_id TEXT, last_health_check_at REAL, last_health_status TEXT NOT NULL);",
        "CREATE TABLE IF NOT EXISTS office_preferences (id TEXT PRIMARY KEY, pptx_enabled INTEGER NOT NULL, docx_enabled INTEGER NOT NULL, xlsx_enabled INTEGER NOT NULL, updated_at REAL NOT NULL);",
        "CREATE TABLE IF NOT EXISTS provider_model_selections (provider_id TEXT PRIMARY KEY, selected_model_id TEXT, available_model_ids_json TEXT NOT NULL, availability_state TEXT NOT NULL, last_refreshed_at REAL, last_safe_error TEXT, updated_at REAL NOT NULL);",
        "CREATE TABLE IF NOT EXISTS hermes_profile_selection (id TEXT PRIMARY KEY, selected_profile_id TEXT, selected_profile_display_name TEXT, available_profiles_json TEXT NOT NULL, availability_state TEXT NOT NULL, last_refreshed_at REAL, last_safe_error TEXT, updated_at REAL NOT NULL);",
        "CREATE TABLE IF NOT EXISTS office_extraction_metadata (id TEXT PRIMARY KEY, asset_id TEXT NOT NULL, office_kind TEXT NOT NULL, provider_id TEXT NOT NULL, hermes_profile_id TEXT NOT NULL, safe_summary TEXT, safe_snippet TEXT, created_at REAL NOT NULL);",
        "CREATE INDEX IF NOT EXISTS idx_office_extraction_metadata_asset ON office_extraction_metadata(asset_id);",
        "CREATE TABLE IF NOT EXISTS generated_content_records (id TEXT PRIMARY KEY, asset_id TEXT NOT NULL, extraction_record_id TEXT NOT NULL, media_type TEXT NOT NULL, output_kind TEXT NOT NULL, provider_id TEXT NOT NULL, provider_mode TEXT NOT NULL, model_id TEXT, hermes_profile_id TEXT, bounded_text TEXT NOT NULL, source_prompt_version TEXT NOT NULL, status TEXT NOT NULL, error_category TEXT, created_at REAL NOT NULL, updated_at REAL NOT NULL);",
        "CREATE INDEX IF NOT EXISTS idx_generated_content_asset ON generated_content_records(asset_id);",
        "CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at REAL NOT NULL);",
        "INSERT OR IGNORE INTO schema_migrations(version, applied_at) VALUES (1, datetime('now'));"
    ]
}
