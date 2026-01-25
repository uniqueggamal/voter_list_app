# Database Cleanup Implementation

## Completed Tasks
- [x] Created CleanupHelper class to manage database file cleanup
- [x] Added app lifecycle management to track app state
- [x] Integrated cleanup logic into main.dart
- [x] Added cleanup call on app startup
- [x] Verified code compiles without errors

## How It Works
1. **Flag-based Detection**: Uses an `app_active.flag` file to detect if app was previously installed
2. **Startup Cleanup**: On app launch, checks for orphaned database files from previous installations
3. **Lifecycle Management**: Marks app as inactive when terminated/paused, active when resumed
4. **Automatic Cleanup**: Removes database files and exported files when app detects previous uninstallation

## Files Cleaned Up
- `voter_list_readable.db` - Main voter database
- `voter_tags.db` - Tags database
- `voter_additional_details.db` - Additional details database
- `notes_list.db` - Notes database
- Exported files (*.pdf, *.xlsx, *.xls)

## Export Tags Feature
- [x] Added 'tags' column to export dialog selectable columns
- [x] Updated _getColumnDisplayName to handle 'tags'
- [x] Added import for TagsDatabaseHelper
- [x] Modified _exportData to fetch and format tags as comma-separated string
- [x] Tags are now included in Excel exports when selected

## Testing Needed
- [ ] Test app installation and uninstallation cycle
- [ ] Verify database files are cleaned up after uninstall
- [ ] Test on different platforms (Android, iOS, Desktop)
- [ ] Verify exported files are also cleaned up
- [ ] Test export functionality with tags selected

## Export Fixes
- [x] Fixed empty Excel export issue by adding validation in export_dialog.dart
- [x] Changed view creation to CREATE OR REPLACE in export_service.dart to prevent conflicts
- [x] Added check for empty voter list before creating Excel file

## Import/Export Column Mapping Fixes
- [x] Added _mapHeaderToKey method in import_service.dart to properly map display column names to internal keys
- [x] Ensures consistent column name handling between export and import operations

## Tag Import Implementation
- [x] Implemented proper tag import functionality in import_service.dart
- [x] Added logic to create new tags if they don't exist during import
- [x] Tags are parsed from comma-separated string and associated with voters
- [x] Added necessary imports for TagsDatabaseHelper and Tag model

## Column Name Change in voterdetails Table
- [x] Renamed "social_media" column to "name_en" in voterdetails table
- [x] Implemented database migration (version 4) to recreate table with new column name
- [x] Updated all code references to use "name_en" instead of "social_media"
- [x] Preserved existing data during migration
