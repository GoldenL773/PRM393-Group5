/// Database constants for table names, column names, and other database-related constants
/// This file centralizes all database schema definitions to ensure consistency
/// across the application and make schema changes easier to manage.
library;

class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'goldfit.db';
  static const int databaseVersion = 3;

  // Table names
  static const String tableClothingItems = 'clothing_items';
  static const String tableOutfits = 'outfits';
  static const String tableOutfitItems = 'outfit_items';
  static const String tableOutfitCalendar = 'outfit_calendar';
  static const String tableUsageHistory = 'usage_history';
  static const String tableBasePhotos = 'base_photos';
  static const String tableTryOnSessions = 'try_on_sessions';
  static const String tableUserPreferences = 'user_preferences';
  static const String tableTags = 'tags';
  static const String tableClothingTags = 'clothing_tags';

  // clothing_items table columns
  static const String columnId = 'id';
  static const String columnImagePath = 'image_path';
  static const String columnCleanedImagePath = 'cleaned_image_path';
  static const String columnType = 'type';
  static const String columnColor = 'color';
  static const String columnSeasons = 'seasons';
  static const String columnPrice = 'price';
  static const String columnUsageCount = 'usage_count';
  static const String columnAiTags = 'ai_tags';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // outfits table columns
  static const String columnName = 'name';
  static const String columnVibe = 'vibe';
  static const String columnThumbnailPath = 'thumbnail_path';
  static const String columnWeatherContext = 'weather_context';
  static const String columnIsFavorite = 'is_favorite';
  static const String columnModelImagePath = 'model_image_path';
  static const String columnResultImagePath = 'result_image_path';

  // outfit_items table columns
  static const String columnOutfitId = 'outfit_id';
  static const String columnClothingItemId = 'clothing_item_id';
  static const String columnLayerOrder = 'layer_order';

  // outfit_calendar table columns
  static const String columnAssignedDate = 'assigned_date';

  // usage_history table columns
  static const String columnWornDate = 'worn_date';

  // base_photos table columns
  static const String columnIsActive = 'is_active';

  // try_on_sessions table columns
  static const String columnBasePhotoId = 'base_photo_id';
  static const String columnMode = 'mode';
  static const String columnSessionResultImagePath = 'session_result_image_path';

  // user_preferences table columns
  static const String columnKey = 'key';
  static const String columnValue = 'value';

  // tags table columns
  static const String columnCategory = 'category';

  // tags table columns
  static const String columnTagId = 'tag_id';

  // Index names
  static const String indexClothingType = 'idx_clothing_type';
  static const String indexClothingColor = 'idx_clothing_color';
  static const String indexClothingCreated = 'idx_clothing_created';
  static const String indexOutfitVibe = 'idx_outfit_vibe';
  static const String indexOutfitCreated = 'idx_outfit_created';
  static const String indexOutfitItemsOutfit = 'idx_outfit_items_outfit';
  static const String indexOutfitItemsItem = 'idx_outfit_items_item';
  static const String indexCalendarDate = 'idx_calendar_date';
  static const String indexCalendarOutfit = 'idx_calendar_outfit';
  static const String indexUsageItem = 'idx_usage_item';
  static const String indexUsageDate = 'idx_usage_date';
  static const String indexBasePhotoActive = 'idx_base_photo_active';
  static const String indexSessionBasePhoto = 'idx_session_base_photo';
  static const String indexSessionCreated = 'idx_session_created';
  static const String indexTagCategory = 'idx_tag_category';
  static const String indexClothingTagsItem = 'idx_clothing_tags_item';
  static const String indexClothingTagsTag = 'idx_clothing_tags_tag';

  // Prevent instantiation
  DatabaseConstants._();
}
