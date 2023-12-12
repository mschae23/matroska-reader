// This file was auto-generated.

pub const MATROSKA_VERSION: u8 = 4;

pub const ElementType = enum {
    integer,
    uinteger,
    float,
    string,
    date,
    utf8,
    master,
    binary,
};

pub const Importance = enum {
    hot,
    important,
    default,
};

pub const ElementInfo = struct {
    id: u32,
    type: ElementType,
    name: []const u8,
    importance: Importance = .default,
    deprecated: bool = false,
};

pub const IdInfo = struct {
    id: u32,
    type: ElementType,
    name: []const u8,
};

pub const ELEMENTS = [_]ElementInfo {
    ElementInfo { .id = 0x1A45DFA3, .type = .master, .name = "EBML", },
    ElementInfo { .id = 0x4286, .type = .uinteger, .name = "EBMLVersion", },
    ElementInfo { .id = 0x42F7, .type = .uinteger, .name = "EBMLReadVersion", },
    ElementInfo { .id = 0x42F2, .type = .uinteger, .name = "EBMLMaxIDLength", },
    ElementInfo { .id = 0x42F3, .type = .uinteger, .name = "EBMLMaxSizeLength", },
    ElementInfo { .id = 0x4282, .type = .string, .name = "DocType", },
    ElementInfo { .id = 0x4287, .type = .uinteger, .name = "DocTypeVersion", },
    ElementInfo { .id = 0x4285, .type = .uinteger, .name = "DocTypeReadVersion", },
    ElementInfo { .id = 0x4281, .type = .master, .name = "DocTypeExtension", },
    ElementInfo { .id = 0x4283, .type = .string, .name = "DocTypeExtensionName", },
    ElementInfo { .id = 0x4284, .type = .uinteger, .name = "DocTypeExtensionVersion", },
    ElementInfo { .id = 0xEC, .type = .binary, .name = "Void", },
    ElementInfo { .id = 0xBF, .type = .binary, .name = "CRC32", },
    ElementInfo { .id = 0x18538067, .type = .master, .name = "Segment", .importance = .important, },
    ElementInfo { .id = 0x114D9B74, .type = .master, .name = "SeekHead", },
    ElementInfo { .id = 0x4DBB, .type = .master, .name = "Seek", },
    ElementInfo { .id = 0x53AB, .type = .binary, .name = "SeekID", },
    ElementInfo { .id = 0x53AC, .type = .uinteger, .name = "SeekPosition", },
    ElementInfo { .id = 0x1549A966, .type = .master, .name = "Info", .importance = .important, },
    ElementInfo { .id = 0x73A4, .type = .binary, .name = "SegmentUUID", },
    ElementInfo { .id = 0x7384, .type = .utf8, .name = "SegmentFilename", },
    ElementInfo { .id = 0x3CB923, .type = .binary, .name = "PrevUUID", },
    ElementInfo { .id = 0x3C83AB, .type = .utf8, .name = "PrevFilename", },
    ElementInfo { .id = 0x3EB923, .type = .binary, .name = "NextUUID", },
    ElementInfo { .id = 0x3E83BB, .type = .utf8, .name = "NextFilename", },
    ElementInfo { .id = 0x4444, .type = .binary, .name = "SegmentFamily", },
    ElementInfo { .id = 0x6924, .type = .master, .name = "ChapterTranslate", },
    ElementInfo { .id = 0x69A5, .type = .binary, .name = "ChapterTranslateID", },
    ElementInfo { .id = 0x69BF, .type = .uinteger, .name = "ChapterTranslateCodec", },
    ElementInfo { .id = 0x69FC, .type = .uinteger, .name = "ChapterTranslateEditionUID", },
    ElementInfo { .id = 0x2AD7B1, .type = .uinteger, .name = "TimestampScale", .importance = .important, },
    ElementInfo { .id = 0x4489, .type = .float, .name = "Duration", },
    ElementInfo { .id = 0x4461, .type = .date, .name = "DateUTC", },
    ElementInfo { .id = 0x7BA9, .type = .utf8, .name = "Title", },
    ElementInfo { .id = 0x4D80, .type = .utf8, .name = "MuxingApp", },
    ElementInfo { .id = 0x5741, .type = .utf8, .name = "WritingApp", },
    ElementInfo { .id = 0x1F43B675, .type = .master, .name = "Cluster", .importance = .hot, },
    ElementInfo { .id = 0xE7, .type = .uinteger, .name = "Timestamp", .importance = .hot, },
    ElementInfo { .id = 0x5854, .type = .master, .name = "SilentTracks", .deprecated = true, },
    ElementInfo { .id = 0x58D7, .type = .uinteger, .name = "SilentTrackNumber", .deprecated = true, },
    ElementInfo { .id = 0xA7, .type = .uinteger, .name = "Position", },
    ElementInfo { .id = 0xAB, .type = .uinteger, .name = "PrevSize", },
    ElementInfo { .id = 0xA3, .type = .binary, .name = "SimpleBlock", .importance = .hot, },
    ElementInfo { .id = 0xA0, .type = .master, .name = "BlockGroup", .importance = .important, },
    ElementInfo { .id = 0xA1, .type = .binary, .name = "Block", .importance = .important, },
    ElementInfo { .id = 0xA2, .type = .binary, .name = "BlockVirtual", .deprecated = true, },
    ElementInfo { .id = 0x75A1, .type = .master, .name = "BlockAdditions", },
    ElementInfo { .id = 0xA6, .type = .master, .name = "BlockMore", },
    ElementInfo { .id = 0xA5, .type = .binary, .name = "BlockAdditional", },
    ElementInfo { .id = 0xEE, .type = .uinteger, .name = "BlockAddID", },
    ElementInfo { .id = 0x9B, .type = .uinteger, .name = "BlockDuration", .importance = .important, },
    ElementInfo { .id = 0xFA, .type = .uinteger, .name = "ReferencePriority", },
    ElementInfo { .id = 0xFB, .type = .integer, .name = "ReferenceBlock", },
    ElementInfo { .id = 0xFD, .type = .integer, .name = "ReferenceVirtual", .deprecated = true, },
    ElementInfo { .id = 0xA4, .type = .binary, .name = "CodecState", },
    ElementInfo { .id = 0x75A2, .type = .integer, .name = "DiscardPadding", },
    ElementInfo { .id = 0x8E, .type = .master, .name = "Slices", .deprecated = true, },
    ElementInfo { .id = 0xE8, .type = .master, .name = "TimeSlice", .deprecated = true, },
    ElementInfo { .id = 0xCC, .type = .uinteger, .name = "LaceNumber", .deprecated = true, },
    ElementInfo { .id = 0xCD, .type = .uinteger, .name = "FrameNumber", .deprecated = true, },
    ElementInfo { .id = 0xCB, .type = .uinteger, .name = "BlockAdditionID", .deprecated = true, },
    ElementInfo { .id = 0xCE, .type = .uinteger, .name = "Delay", .deprecated = true, },
    ElementInfo { .id = 0xCF, .type = .uinteger, .name = "SliceDuration", .deprecated = true, },
    ElementInfo { .id = 0xC8, .type = .master, .name = "ReferenceFrame", .deprecated = true, },
    ElementInfo { .id = 0xC9, .type = .uinteger, .name = "ReferenceOffset", .deprecated = true, },
    ElementInfo { .id = 0xCA, .type = .uinteger, .name = "ReferenceTimestamp", .deprecated = true, },
    ElementInfo { .id = 0xAF, .type = .binary, .name = "EncryptedBlock", .deprecated = true, },
    ElementInfo { .id = 0x1654AE6B, .type = .master, .name = "Tracks", .importance = .important, },
    ElementInfo { .id = 0xAE, .type = .master, .name = "TrackEntry", .importance = .important, },
    ElementInfo { .id = 0xD7, .type = .uinteger, .name = "TrackNumber", .importance = .important, },
    ElementInfo { .id = 0x73C5, .type = .uinteger, .name = "TrackUID", },
    ElementInfo { .id = 0x83, .type = .uinteger, .name = "TrackType", .importance = .important, },
    ElementInfo { .id = 0xB9, .type = .uinteger, .name = "FlagEnabled", },
    ElementInfo { .id = 0x88, .type = .uinteger, .name = "FlagDefault", },
    ElementInfo { .id = 0x55AA, .type = .uinteger, .name = "FlagForced", },
    ElementInfo { .id = 0x55AB, .type = .uinteger, .name = "FlagHearingImpaired", },
    ElementInfo { .id = 0x55AC, .type = .uinteger, .name = "FlagVisualImpaired", },
    ElementInfo { .id = 0x55AD, .type = .uinteger, .name = "FlagTextDescriptions", },
    ElementInfo { .id = 0x55AE, .type = .uinteger, .name = "FlagOriginal", },
    ElementInfo { .id = 0x55AF, .type = .uinteger, .name = "FlagCommentary", },
    ElementInfo { .id = 0x9C, .type = .uinteger, .name = "FlagLacing", },
    ElementInfo { .id = 0x6DE7, .type = .uinteger, .name = "MinCache", .deprecated = true, },
    ElementInfo { .id = 0x6DF8, .type = .uinteger, .name = "MaxCache", .deprecated = true, },
    ElementInfo { .id = 0x23E383, .type = .uinteger, .name = "DefaultDuration", },
    ElementInfo { .id = 0x234E7A, .type = .uinteger, .name = "DefaultDecodedFieldDuration", },
    ElementInfo { .id = 0x23314F, .type = .float, .name = "TrackTimestampScale", .deprecated = true, },
    ElementInfo { .id = 0x537F, .type = .integer, .name = "TrackOffset", .deprecated = true, },
    ElementInfo { .id = 0x55EE, .type = .uinteger, .name = "MaxBlockAdditionID", },
    ElementInfo { .id = 0x41E4, .type = .master, .name = "BlockAdditionMapping", },
    ElementInfo { .id = 0x41F0, .type = .uinteger, .name = "BlockAddIDValue", },
    ElementInfo { .id = 0x41A4, .type = .string, .name = "BlockAddIDName", },
    ElementInfo { .id = 0x41E7, .type = .uinteger, .name = "BlockAddIDType", },
    ElementInfo { .id = 0x41ED, .type = .binary, .name = "BlockAddIDExtraData", },
    ElementInfo { .id = 0x536E, .type = .utf8, .name = "Name", },
    ElementInfo { .id = 0x22B59C, .type = .string, .name = "Language", },
    ElementInfo { .id = 0x22B59D, .type = .string, .name = "LanguageBCP47", },
    ElementInfo { .id = 0x86, .type = .string, .name = "CodecID", .importance = .important, },
    ElementInfo { .id = 0x63A2, .type = .binary, .name = "CodecPrivate", .importance = .important, },
    ElementInfo { .id = 0x258688, .type = .utf8, .name = "CodecName", },
    ElementInfo { .id = 0x7446, .type = .uinteger, .name = "AttachmentLink", .deprecated = true, },
    ElementInfo { .id = 0x3A9697, .type = .utf8, .name = "CodecSettings", .deprecated = true, },
    ElementInfo { .id = 0x3B4040, .type = .string, .name = "CodecInfoURL", .deprecated = true, },
    ElementInfo { .id = 0x26B240, .type = .string, .name = "CodecDownloadURL", .deprecated = true, },
    ElementInfo { .id = 0xAA, .type = .uinteger, .name = "CodecDecodeAll", .deprecated = true, },
    ElementInfo { .id = 0x6FAB, .type = .uinteger, .name = "TrackOverlay", .deprecated = true, },
    ElementInfo { .id = 0x56AA, .type = .uinteger, .name = "CodecDelay", },
    ElementInfo { .id = 0x56BB, .type = .uinteger, .name = "SeekPreRoll", },
    ElementInfo { .id = 0x6624, .type = .master, .name = "TrackTranslate", },
    ElementInfo { .id = 0x66A5, .type = .binary, .name = "TrackTranslateTrackID", },
    ElementInfo { .id = 0x66BF, .type = .uinteger, .name = "TrackTranslateCodec", },
    ElementInfo { .id = 0x66FC, .type = .uinteger, .name = "TrackTranslateEditionUID", },
    ElementInfo { .id = 0xE0, .type = .master, .name = "Video", .importance = .important, },
    ElementInfo { .id = 0x9A, .type = .uinteger, .name = "FlagInterlaced", },
    ElementInfo { .id = 0x9D, .type = .uinteger, .name = "FieldOrder", },
    ElementInfo { .id = 0x53B8, .type = .uinteger, .name = "StereoMode", },
    ElementInfo { .id = 0x53C0, .type = .uinteger, .name = "AlphaMode", },
    ElementInfo { .id = 0x53B9, .type = .uinteger, .name = "OldStereoMode", .deprecated = true, },
    ElementInfo { .id = 0xB0, .type = .uinteger, .name = "PixelWidth", .importance = .important, },
    ElementInfo { .id = 0xBA, .type = .uinteger, .name = "PixelHeight", .importance = .important, },
    ElementInfo { .id = 0x54AA, .type = .uinteger, .name = "PixelCropBottom", },
    ElementInfo { .id = 0x54BB, .type = .uinteger, .name = "PixelCropTop", },
    ElementInfo { .id = 0x54CC, .type = .uinteger, .name = "PixelCropLeft", },
    ElementInfo { .id = 0x54DD, .type = .uinteger, .name = "PixelCropRight", },
    ElementInfo { .id = 0x54B0, .type = .uinteger, .name = "DisplayWidth", },
    ElementInfo { .id = 0x54BA, .type = .uinteger, .name = "DisplayHeight", },
    ElementInfo { .id = 0x54B2, .type = .uinteger, .name = "DisplayUnit", },
    ElementInfo { .id = 0x54B3, .type = .uinteger, .name = "AspectRatioType", .deprecated = true, },
    ElementInfo { .id = 0x2EB524, .type = .binary, .name = "UncompressedFourCC", },
    ElementInfo { .id = 0x2FB523, .type = .float, .name = "GammaValue", .deprecated = true, },
    ElementInfo { .id = 0x2383E3, .type = .float, .name = "FrameRate", .deprecated = true, },
    ElementInfo { .id = 0x55B0, .type = .master, .name = "Colour", },
    ElementInfo { .id = 0x55B1, .type = .uinteger, .name = "MatrixCoefficients", },
    ElementInfo { .id = 0x55B2, .type = .uinteger, .name = "BitsPerChannel", },
    ElementInfo { .id = 0x55B3, .type = .uinteger, .name = "ChromaSubsamplingHorz", },
    ElementInfo { .id = 0x55B4, .type = .uinteger, .name = "ChromaSubsamplingVert", },
    ElementInfo { .id = 0x55B5, .type = .uinteger, .name = "CbSubsamplingHorz", },
    ElementInfo { .id = 0x55B6, .type = .uinteger, .name = "CbSubsamplingVert", },
    ElementInfo { .id = 0x55B7, .type = .uinteger, .name = "ChromaSitingHorz", },
    ElementInfo { .id = 0x55B8, .type = .uinteger, .name = "ChromaSitingVert", },
    ElementInfo { .id = 0x55B9, .type = .uinteger, .name = "Range", },
    ElementInfo { .id = 0x55BA, .type = .uinteger, .name = "TransferCharacteristics", },
    ElementInfo { .id = 0x55BB, .type = .uinteger, .name = "Primaries", },
    ElementInfo { .id = 0x55BC, .type = .uinteger, .name = "MaxCLL", },
    ElementInfo { .id = 0x55BD, .type = .uinteger, .name = "MaxFALL", },
    ElementInfo { .id = 0x55D0, .type = .master, .name = "MasteringMetadata", },
    ElementInfo { .id = 0x55D1, .type = .float, .name = "PrimaryRChromaticityX", },
    ElementInfo { .id = 0x55D2, .type = .float, .name = "PrimaryRChromaticityY", },
    ElementInfo { .id = 0x55D3, .type = .float, .name = "PrimaryGChromaticityX", },
    ElementInfo { .id = 0x55D4, .type = .float, .name = "PrimaryGChromaticityY", },
    ElementInfo { .id = 0x55D5, .type = .float, .name = "PrimaryBChromaticityX", },
    ElementInfo { .id = 0x55D6, .type = .float, .name = "PrimaryBChromaticityY", },
    ElementInfo { .id = 0x55D7, .type = .float, .name = "WhitePointChromaticityX", },
    ElementInfo { .id = 0x55D8, .type = .float, .name = "WhitePointChromaticityY", },
    ElementInfo { .id = 0x55D9, .type = .float, .name = "LuminanceMax", },
    ElementInfo { .id = 0x55DA, .type = .float, .name = "LuminanceMin", },
    ElementInfo { .id = 0x7670, .type = .master, .name = "Projection", },
    ElementInfo { .id = 0x7671, .type = .uinteger, .name = "ProjectionType", },
    ElementInfo { .id = 0x7672, .type = .binary, .name = "ProjectionPrivate", },
    ElementInfo { .id = 0x7673, .type = .float, .name = "ProjectionPoseYaw", },
    ElementInfo { .id = 0x7674, .type = .float, .name = "ProjectionPosePitch", },
    ElementInfo { .id = 0x7675, .type = .float, .name = "ProjectionPoseRoll", },
    ElementInfo { .id = 0xE1, .type = .master, .name = "Audio", .importance = .important, },
    ElementInfo { .id = 0xB5, .type = .float, .name = "SamplingFrequency", .importance = .important, },
    ElementInfo { .id = 0x78B5, .type = .float, .name = "OutputSamplingFrequency", },
    ElementInfo { .id = 0x9F, .type = .uinteger, .name = "Channels", .importance = .important, },
    ElementInfo { .id = 0x7D7B, .type = .binary, .name = "ChannelPositions", .deprecated = true, },
    ElementInfo { .id = 0x6264, .type = .uinteger, .name = "BitDepth", },
    ElementInfo { .id = 0x52F1, .type = .uinteger, .name = "Emphasis", },
    ElementInfo { .id = 0xE2, .type = .master, .name = "TrackOperation", },
    ElementInfo { .id = 0xE3, .type = .master, .name = "TrackCombinePlanes", },
    ElementInfo { .id = 0xE4, .type = .master, .name = "TrackPlane", },
    ElementInfo { .id = 0xE5, .type = .uinteger, .name = "TrackPlaneUID", },
    ElementInfo { .id = 0xE6, .type = .uinteger, .name = "TrackPlaneType", },
    ElementInfo { .id = 0xE9, .type = .master, .name = "TrackJoinBlocks", },
    ElementInfo { .id = 0xED, .type = .uinteger, .name = "TrackJoinUID", },
    ElementInfo { .id = 0xC0, .type = .uinteger, .name = "TrickTrackUID", .deprecated = true, },
    ElementInfo { .id = 0xC1, .type = .binary, .name = "TrickTrackSegmentUID", .deprecated = true, },
    ElementInfo { .id = 0xC6, .type = .uinteger, .name = "TrickTrackFlag", .deprecated = true, },
    ElementInfo { .id = 0xC7, .type = .uinteger, .name = "TrickMasterTrackUID", .deprecated = true, },
    ElementInfo { .id = 0xC4, .type = .binary, .name = "TrickMasterTrackSegmentUID", .deprecated = true, },
    ElementInfo { .id = 0x6D80, .type = .master, .name = "ContentEncodings", },
    ElementInfo { .id = 0x6240, .type = .master, .name = "ContentEncoding", },
    ElementInfo { .id = 0x5031, .type = .uinteger, .name = "ContentEncodingOrder", },
    ElementInfo { .id = 0x5032, .type = .uinteger, .name = "ContentEncodingScope", },
    ElementInfo { .id = 0x5033, .type = .uinteger, .name = "ContentEncodingType", },
    ElementInfo { .id = 0x5034, .type = .master, .name = "ContentCompression", .importance = .important, },
    ElementInfo { .id = 0x4254, .type = .uinteger, .name = "ContentCompAlgo", },
    ElementInfo { .id = 0x4255, .type = .binary, .name = "ContentCompSettings", },
    ElementInfo { .id = 0x5035, .type = .master, .name = "ContentEncryption", },
    ElementInfo { .id = 0x47E1, .type = .uinteger, .name = "ContentEncAlgo", },
    ElementInfo { .id = 0x47E2, .type = .binary, .name = "ContentEncKeyID", },
    ElementInfo { .id = 0x47E7, .type = .master, .name = "ContentEncAESSettings", },
    ElementInfo { .id = 0x47E8, .type = .uinteger, .name = "AESSettingsCipherMode", },
    ElementInfo { .id = 0x47E3, .type = .binary, .name = "ContentSignature", .deprecated = true, },
    ElementInfo { .id = 0x47E4, .type = .binary, .name = "ContentSigKeyID", .deprecated = true, },
    ElementInfo { .id = 0x47E5, .type = .uinteger, .name = "ContentSigAlgo", .deprecated = true, },
    ElementInfo { .id = 0x47E6, .type = .uinteger, .name = "ContentSigHashAlgo", .deprecated = true, },
    ElementInfo { .id = 0x1C53BB6B, .type = .master, .name = "Cues", },
    ElementInfo { .id = 0xBB, .type = .master, .name = "CuePoint", },
    ElementInfo { .id = 0xB3, .type = .uinteger, .name = "CueTime", },
    ElementInfo { .id = 0xB7, .type = .master, .name = "CueTrackPositions", },
    ElementInfo { .id = 0xF7, .type = .uinteger, .name = "CueTrack", },
    ElementInfo { .id = 0xF1, .type = .uinteger, .name = "CueClusterPosition", },
    ElementInfo { .id = 0xF0, .type = .uinteger, .name = "CueRelativePosition", },
    ElementInfo { .id = 0xB2, .type = .uinteger, .name = "CueDuration", },
    ElementInfo { .id = 0x5378, .type = .uinteger, .name = "CueBlockNumber", },
    ElementInfo { .id = 0xEA, .type = .uinteger, .name = "CueCodecState", },
    ElementInfo { .id = 0xDB, .type = .master, .name = "CueReference", },
    ElementInfo { .id = 0x96, .type = .uinteger, .name = "CueRefTime", },
    ElementInfo { .id = 0x97, .type = .uinteger, .name = "CueRefCluster", .deprecated = true, },
    ElementInfo { .id = 0x535F, .type = .uinteger, .name = "CueRefNumber", .deprecated = true, },
    ElementInfo { .id = 0xEB, .type = .uinteger, .name = "CueRefCodecState", .deprecated = true, },
    ElementInfo { .id = 0x1941A469, .type = .master, .name = "Attachments", },
    ElementInfo { .id = 0x61A7, .type = .master, .name = "AttachedFile", },
    ElementInfo { .id = 0x467E, .type = .utf8, .name = "FileDescription", },
    ElementInfo { .id = 0x466E, .type = .utf8, .name = "FileName", },
    ElementInfo { .id = 0x4660, .type = .string, .name = "FileMediaType", },
    ElementInfo { .id = 0x465C, .type = .binary, .name = "FileData", },
    ElementInfo { .id = 0x46AE, .type = .uinteger, .name = "FileUID", },
    ElementInfo { .id = 0x4675, .type = .binary, .name = "FileReferral", .deprecated = true, },
    ElementInfo { .id = 0x4661, .type = .uinteger, .name = "FileUsedStartTime", .deprecated = true, },
    ElementInfo { .id = 0x4662, .type = .uinteger, .name = "FileUsedEndTime", .deprecated = true, },
    ElementInfo { .id = 0x1043A770, .type = .master, .name = "Chapters", },
    ElementInfo { .id = 0x45B9, .type = .master, .name = "EditionEntry", },
    ElementInfo { .id = 0x45BC, .type = .uinteger, .name = "EditionUID", },
    ElementInfo { .id = 0x45BD, .type = .uinteger, .name = "EditionFlagHidden", },
    ElementInfo { .id = 0x45DB, .type = .uinteger, .name = "EditionFlagDefault", },
    ElementInfo { .id = 0x45DD, .type = .uinteger, .name = "EditionFlagOrdered", },
    ElementInfo { .id = 0x4520, .type = .master, .name = "EditionDisplay", },
    ElementInfo { .id = 0x4521, .type = .utf8, .name = "EditionString", },
    ElementInfo { .id = 0x45E4, .type = .string, .name = "EditionLanguageIETF", },
    ElementInfo { .id = 0xB6, .type = .master, .name = "ChapterAtom", },
    ElementInfo { .id = 0x73C4, .type = .uinteger, .name = "ChapterUID", },
    ElementInfo { .id = 0x5654, .type = .utf8, .name = "ChapterStringUID", },
    ElementInfo { .id = 0x91, .type = .uinteger, .name = "ChapterTimeStart", },
    ElementInfo { .id = 0x92, .type = .uinteger, .name = "ChapterTimeEnd", },
    ElementInfo { .id = 0x98, .type = .uinteger, .name = "ChapterFlagHidden", },
    ElementInfo { .id = 0x4598, .type = .uinteger, .name = "ChapterFlagEnabled", },
    ElementInfo { .id = 0x6E67, .type = .binary, .name = "ChapterSegmentUUID", },
    ElementInfo { .id = 0x4588, .type = .uinteger, .name = "ChapterSkipType", },
    ElementInfo { .id = 0x6EBC, .type = .uinteger, .name = "ChapterSegmentEditionUID", },
    ElementInfo { .id = 0x63C3, .type = .uinteger, .name = "ChapterPhysicalEquiv", },
    ElementInfo { .id = 0x8F, .type = .master, .name = "ChapterTrack", },
    ElementInfo { .id = 0x89, .type = .uinteger, .name = "ChapterTrackUID", },
    ElementInfo { .id = 0x80, .type = .master, .name = "ChapterDisplay", },
    ElementInfo { .id = 0x85, .type = .utf8, .name = "ChapString", },
    ElementInfo { .id = 0x437C, .type = .string, .name = "ChapLanguage", },
    ElementInfo { .id = 0x437D, .type = .string, .name = "ChapLanguageBCP47", },
    ElementInfo { .id = 0x437E, .type = .string, .name = "ChapCountry", },
    ElementInfo { .id = 0x6944, .type = .master, .name = "ChapProcess", },
    ElementInfo { .id = 0x6955, .type = .uinteger, .name = "ChapProcessCodecID", },
    ElementInfo { .id = 0x450D, .type = .binary, .name = "ChapProcessPrivate", },
    ElementInfo { .id = 0x6911, .type = .master, .name = "ChapProcessCommand", },
    ElementInfo { .id = 0x6922, .type = .uinteger, .name = "ChapProcessTime", },
    ElementInfo { .id = 0x6933, .type = .binary, .name = "ChapProcessData", },
    ElementInfo { .id = 0x1254C367, .type = .master, .name = "Tags", },
    ElementInfo { .id = 0x7373, .type = .master, .name = "Tag", },
    ElementInfo { .id = 0x63C0, .type = .master, .name = "Targets", },
    ElementInfo { .id = 0x68CA, .type = .uinteger, .name = "TargetTypeValue", },
    ElementInfo { .id = 0x63CA, .type = .string, .name = "TargetType", },
    ElementInfo { .id = 0x63C5, .type = .uinteger, .name = "TagTrackUID", },
    ElementInfo { .id = 0x63C9, .type = .uinteger, .name = "TagEditionUID", },
    ElementInfo { .id = 0x63C4, .type = .uinteger, .name = "TagChapterUID", },
    ElementInfo { .id = 0x63C6, .type = .uinteger, .name = "TagAttachmentUID", },
    ElementInfo { .id = 0x67C8, .type = .master, .name = "SimpleTag", },
    ElementInfo { .id = 0x45A3, .type = .utf8, .name = "TagName", },
    ElementInfo { .id = 0x447A, .type = .string, .name = "TagLanguage", },
    ElementInfo { .id = 0x447B, .type = .string, .name = "TagLanguageBCP47", },
    ElementInfo { .id = 0x4484, .type = .uinteger, .name = "TagDefault", },
    ElementInfo { .id = 0x44B4, .type = .uinteger, .name = "TagDefaultBogus", .deprecated = true, },
    ElementInfo { .id = 0x4487, .type = .utf8, .name = "TagString", },
    ElementInfo { .id = 0x4485, .type = .binary, .name = "TagBinary", },
};

pub const HOT_ELEMENTS = [_]IdInfo {
    IdInfo { .id = 0x1F43B675, .type = .master, .name = "Cluster" },
    IdInfo { .id = 0xE7, .type = .uinteger, .name = "Timestamp" },
    IdInfo { .id = 0xA3, .type = .binary, .name = "SimpleBlock" },
};

pub const IMPORTANT_ELEMENTS = [_]IdInfo {
    IdInfo { .id = 0x18538067, .type = .master, .name = "Segment" },
    IdInfo { .id = 0x1549A966, .type = .master, .name = "Info" },
    IdInfo { .id = 0x2AD7B1, .type = .uinteger, .name = "TimestampScale" },
    IdInfo { .id = 0xA0, .type = .master, .name = "BlockGroup" },
    IdInfo { .id = 0xA1, .type = .binary, .name = "Block" },
    IdInfo { .id = 0x9B, .type = .uinteger, .name = "BlockDuration" },
    IdInfo { .id = 0x1654AE6B, .type = .master, .name = "Tracks" },
    IdInfo { .id = 0xAE, .type = .master, .name = "TrackEntry" },
    IdInfo { .id = 0xD7, .type = .uinteger, .name = "TrackNumber" },
    IdInfo { .id = 0x83, .type = .uinteger, .name = "TrackType" },
    IdInfo { .id = 0x86, .type = .string, .name = "CodecID" },
    IdInfo { .id = 0x63A2, .type = .binary, .name = "CodecPrivate" },
    IdInfo { .id = 0xE0, .type = .master, .name = "Video" },
    IdInfo { .id = 0xB0, .type = .uinteger, .name = "PixelWidth" },
    IdInfo { .id = 0xBA, .type = .uinteger, .name = "PixelHeight" },
    IdInfo { .id = 0xE1, .type = .master, .name = "Audio" },
    IdInfo { .id = 0xB5, .type = .float, .name = "SamplingFrequency" },
    IdInfo { .id = 0x9F, .type = .uinteger, .name = "Channels" },
    IdInfo { .id = 0x5034, .type = .master, .name = "ContentCompression" },
};

pub const ID_Segment: u32 = 0x18538067;
pub const ID_SeekHead: u32 = 0x114D9B74;
pub const ID_Seek: u32 = 0x4DBB;
pub const ID_SeekID: u32 = 0x53AB;
pub const ID_SeekPosition: u32 = 0x53AC;
pub const ID_Info: u32 = 0x1549A966;
pub const ID_SegmentUUID: u32 = 0x73A4;
pub const ID_SegmentFilename: u32 = 0x7384;
pub const ID_PrevUUID: u32 = 0x3CB923;
pub const ID_PrevFilename: u32 = 0x3C83AB;
pub const ID_NextUUID: u32 = 0x3EB923;
pub const ID_NextFilename: u32 = 0x3E83BB;
pub const ID_SegmentFamily: u32 = 0x4444;
pub const ID_ChapterTranslate: u32 = 0x6924;
pub const ID_ChapterTranslateID: u32 = 0x69A5;
pub const ID_ChapterTranslateCodec: u32 = 0x69BF;
pub const ID_ChapterTranslateEditionUID: u32 = 0x69FC;
pub const ID_TimestampScale: u32 = 0x2AD7B1;
pub const ID_Duration: u32 = 0x4489;
pub const ID_DateUTC: u32 = 0x4461;
pub const ID_Title: u32 = 0x7BA9;
pub const ID_MuxingApp: u32 = 0x4D80;
pub const ID_WritingApp: u32 = 0x5741;
pub const ID_Cluster: u32 = 0x1F43B675;
pub const ID_Timestamp: u32 = 0xE7;
pub const ID_SilentTracks: u32 = 0x5854; // Deprecated
pub const ID_SilentTrackNumber: u32 = 0x58D7; // Deprecated
pub const ID_Position: u32 = 0xA7;
pub const ID_PrevSize: u32 = 0xAB;
pub const ID_SimpleBlock: u32 = 0xA3;
pub const ID_BlockGroup: u32 = 0xA0;
pub const ID_Block: u32 = 0xA1;
pub const ID_BlockVirtual: u32 = 0xA2; // Deprecated
pub const ID_BlockAdditions: u32 = 0x75A1;
pub const ID_BlockMore: u32 = 0xA6;
pub const ID_BlockAdditional: u32 = 0xA5;
pub const ID_BlockAddID: u32 = 0xEE;
pub const ID_BlockDuration: u32 = 0x9B;
pub const ID_ReferencePriority: u32 = 0xFA;
pub const ID_ReferenceBlock: u32 = 0xFB;
pub const ID_ReferenceVirtual: u32 = 0xFD; // Deprecated
pub const ID_CodecState: u32 = 0xA4;
pub const ID_DiscardPadding: u32 = 0x75A2;
pub const ID_Slices: u32 = 0x8E; // Deprecated
pub const ID_TimeSlice: u32 = 0xE8; // Deprecated
pub const ID_LaceNumber: u32 = 0xCC; // Deprecated
pub const ID_FrameNumber: u32 = 0xCD; // Deprecated
pub const ID_BlockAdditionID: u32 = 0xCB; // Deprecated
pub const ID_Delay: u32 = 0xCE; // Deprecated
pub const ID_SliceDuration: u32 = 0xCF; // Deprecated
pub const ID_ReferenceFrame: u32 = 0xC8; // Deprecated
pub const ID_ReferenceOffset: u32 = 0xC9; // Deprecated
pub const ID_ReferenceTimestamp: u32 = 0xCA; // Deprecated
pub const ID_EncryptedBlock: u32 = 0xAF; // Deprecated
pub const ID_Tracks: u32 = 0x1654AE6B;
pub const ID_TrackEntry: u32 = 0xAE;
pub const ID_TrackNumber: u32 = 0xD7;
pub const ID_TrackUID: u32 = 0x73C5;
pub const ID_TrackType: u32 = 0x83;
pub const ID_FlagEnabled: u32 = 0xB9;
pub const ID_FlagDefault: u32 = 0x88;
pub const ID_FlagForced: u32 = 0x55AA;
pub const ID_FlagHearingImpaired: u32 = 0x55AB;
pub const ID_FlagVisualImpaired: u32 = 0x55AC;
pub const ID_FlagTextDescriptions: u32 = 0x55AD;
pub const ID_FlagOriginal: u32 = 0x55AE;
pub const ID_FlagCommentary: u32 = 0x55AF;
pub const ID_FlagLacing: u32 = 0x9C;
pub const ID_MinCache: u32 = 0x6DE7; // Deprecated
pub const ID_MaxCache: u32 = 0x6DF8; // Deprecated
pub const ID_DefaultDuration: u32 = 0x23E383;
pub const ID_DefaultDecodedFieldDuration: u32 = 0x234E7A;
pub const ID_TrackTimestampScale: u32 = 0x23314F; // Deprecated
pub const ID_TrackOffset: u32 = 0x537F; // Deprecated
pub const ID_MaxBlockAdditionID: u32 = 0x55EE;
pub const ID_BlockAdditionMapping: u32 = 0x41E4;
pub const ID_BlockAddIDValue: u32 = 0x41F0;
pub const ID_BlockAddIDName: u32 = 0x41A4;
pub const ID_BlockAddIDType: u32 = 0x41E7;
pub const ID_BlockAddIDExtraData: u32 = 0x41ED;
pub const ID_Name: u32 = 0x536E;
pub const ID_Language: u32 = 0x22B59C;
pub const ID_LanguageBCP47: u32 = 0x22B59D;
pub const ID_CodecID: u32 = 0x86;
pub const ID_CodecPrivate: u32 = 0x63A2;
pub const ID_CodecName: u32 = 0x258688;
pub const ID_AttachmentLink: u32 = 0x7446; // Deprecated
pub const ID_CodecSettings: u32 = 0x3A9697; // Deprecated
pub const ID_CodecInfoURL: u32 = 0x3B4040; // Deprecated
pub const ID_CodecDownloadURL: u32 = 0x26B240; // Deprecated
pub const ID_CodecDecodeAll: u32 = 0xAA; // Deprecated
pub const ID_TrackOverlay: u32 = 0x6FAB; // Deprecated
pub const ID_CodecDelay: u32 = 0x56AA;
pub const ID_SeekPreRoll: u32 = 0x56BB;
pub const ID_TrackTranslate: u32 = 0x6624;
pub const ID_TrackTranslateTrackID: u32 = 0x66A5;
pub const ID_TrackTranslateCodec: u32 = 0x66BF;
pub const ID_TrackTranslateEditionUID: u32 = 0x66FC;
pub const ID_Video: u32 = 0xE0;
pub const ID_FlagInterlaced: u32 = 0x9A;
pub const ID_FieldOrder: u32 = 0x9D;
pub const ID_StereoMode: u32 = 0x53B8;
pub const ID_AlphaMode: u32 = 0x53C0;
pub const ID_OldStereoMode: u32 = 0x53B9; // Deprecated
pub const ID_PixelWidth: u32 = 0xB0;
pub const ID_PixelHeight: u32 = 0xBA;
pub const ID_PixelCropBottom: u32 = 0x54AA;
pub const ID_PixelCropTop: u32 = 0x54BB;
pub const ID_PixelCropLeft: u32 = 0x54CC;
pub const ID_PixelCropRight: u32 = 0x54DD;
pub const ID_DisplayWidth: u32 = 0x54B0;
pub const ID_DisplayHeight: u32 = 0x54BA;
pub const ID_DisplayUnit: u32 = 0x54B2;
pub const ID_AspectRatioType: u32 = 0x54B3; // Deprecated
pub const ID_UncompressedFourCC: u32 = 0x2EB524;
pub const ID_GammaValue: u32 = 0x2FB523; // Deprecated
pub const ID_FrameRate: u32 = 0x2383E3; // Deprecated
pub const ID_Colour: u32 = 0x55B0;
pub const ID_MatrixCoefficients: u32 = 0x55B1;
pub const ID_BitsPerChannel: u32 = 0x55B2;
pub const ID_ChromaSubsamplingHorz: u32 = 0x55B3;
pub const ID_ChromaSubsamplingVert: u32 = 0x55B4;
pub const ID_CbSubsamplingHorz: u32 = 0x55B5;
pub const ID_CbSubsamplingVert: u32 = 0x55B6;
pub const ID_ChromaSitingHorz: u32 = 0x55B7;
pub const ID_ChromaSitingVert: u32 = 0x55B8;
pub const ID_Range: u32 = 0x55B9;
pub const ID_TransferCharacteristics: u32 = 0x55BA;
pub const ID_Primaries: u32 = 0x55BB;
pub const ID_MaxCLL: u32 = 0x55BC;
pub const ID_MaxFALL: u32 = 0x55BD;
pub const ID_MasteringMetadata: u32 = 0x55D0;
pub const ID_PrimaryRChromaticityX: u32 = 0x55D1;
pub const ID_PrimaryRChromaticityY: u32 = 0x55D2;
pub const ID_PrimaryGChromaticityX: u32 = 0x55D3;
pub const ID_PrimaryGChromaticityY: u32 = 0x55D4;
pub const ID_PrimaryBChromaticityX: u32 = 0x55D5;
pub const ID_PrimaryBChromaticityY: u32 = 0x55D6;
pub const ID_WhitePointChromaticityX: u32 = 0x55D7;
pub const ID_WhitePointChromaticityY: u32 = 0x55D8;
pub const ID_LuminanceMax: u32 = 0x55D9;
pub const ID_LuminanceMin: u32 = 0x55DA;
pub const ID_Projection: u32 = 0x7670;
pub const ID_ProjectionType: u32 = 0x7671;
pub const ID_ProjectionPrivate: u32 = 0x7672;
pub const ID_ProjectionPoseYaw: u32 = 0x7673;
pub const ID_ProjectionPosePitch: u32 = 0x7674;
pub const ID_ProjectionPoseRoll: u32 = 0x7675;
pub const ID_Audio: u32 = 0xE1;
pub const ID_SamplingFrequency: u32 = 0xB5;
pub const ID_OutputSamplingFrequency: u32 = 0x78B5;
pub const ID_Channels: u32 = 0x9F;
pub const ID_ChannelPositions: u32 = 0x7D7B; // Deprecated
pub const ID_BitDepth: u32 = 0x6264;
pub const ID_Emphasis: u32 = 0x52F1;
pub const ID_TrackOperation: u32 = 0xE2;
pub const ID_TrackCombinePlanes: u32 = 0xE3;
pub const ID_TrackPlane: u32 = 0xE4;
pub const ID_TrackPlaneUID: u32 = 0xE5;
pub const ID_TrackPlaneType: u32 = 0xE6;
pub const ID_TrackJoinBlocks: u32 = 0xE9;
pub const ID_TrackJoinUID: u32 = 0xED;
pub const ID_TrickTrackUID: u32 = 0xC0; // Deprecated
pub const ID_TrickTrackSegmentUID: u32 = 0xC1; // Deprecated
pub const ID_TrickTrackFlag: u32 = 0xC6; // Deprecated
pub const ID_TrickMasterTrackUID: u32 = 0xC7; // Deprecated
pub const ID_TrickMasterTrackSegmentUID: u32 = 0xC4; // Deprecated
pub const ID_ContentEncodings: u32 = 0x6D80;
pub const ID_ContentEncoding: u32 = 0x6240;
pub const ID_ContentEncodingOrder: u32 = 0x5031;
pub const ID_ContentEncodingScope: u32 = 0x5032;
pub const ID_ContentEncodingType: u32 = 0x5033;
pub const ID_ContentCompression: u32 = 0x5034;
pub const ID_ContentCompAlgo: u32 = 0x4254;
pub const ID_ContentCompSettings: u32 = 0x4255;
pub const ID_ContentEncryption: u32 = 0x5035;
pub const ID_ContentEncAlgo: u32 = 0x47E1;
pub const ID_ContentEncKeyID: u32 = 0x47E2;
pub const ID_ContentEncAESSettings: u32 = 0x47E7;
pub const ID_AESSettingsCipherMode: u32 = 0x47E8;
pub const ID_ContentSignature: u32 = 0x47E3; // Deprecated
pub const ID_ContentSigKeyID: u32 = 0x47E4; // Deprecated
pub const ID_ContentSigAlgo: u32 = 0x47E5; // Deprecated
pub const ID_ContentSigHashAlgo: u32 = 0x47E6; // Deprecated
pub const ID_Cues: u32 = 0x1C53BB6B;
pub const ID_CuePoint: u32 = 0xBB;
pub const ID_CueTime: u32 = 0xB3;
pub const ID_CueTrackPositions: u32 = 0xB7;
pub const ID_CueTrack: u32 = 0xF7;
pub const ID_CueClusterPosition: u32 = 0xF1;
pub const ID_CueRelativePosition: u32 = 0xF0;
pub const ID_CueDuration: u32 = 0xB2;
pub const ID_CueBlockNumber: u32 = 0x5378;
pub const ID_CueCodecState: u32 = 0xEA;
pub const ID_CueReference: u32 = 0xDB;
pub const ID_CueRefTime: u32 = 0x96;
pub const ID_CueRefCluster: u32 = 0x97; // Deprecated
pub const ID_CueRefNumber: u32 = 0x535F; // Deprecated
pub const ID_CueRefCodecState: u32 = 0xEB; // Deprecated
pub const ID_Attachments: u32 = 0x1941A469;
pub const ID_AttachedFile: u32 = 0x61A7;
pub const ID_FileDescription: u32 = 0x467E;
pub const ID_FileName: u32 = 0x466E;
pub const ID_FileMediaType: u32 = 0x4660;
pub const ID_FileData: u32 = 0x465C;
pub const ID_FileUID: u32 = 0x46AE;
pub const ID_FileReferral: u32 = 0x4675; // Deprecated
pub const ID_FileUsedStartTime: u32 = 0x4661; // Deprecated
pub const ID_FileUsedEndTime: u32 = 0x4662; // Deprecated
pub const ID_Chapters: u32 = 0x1043A770;
pub const ID_EditionEntry: u32 = 0x45B9;
pub const ID_EditionUID: u32 = 0x45BC;
pub const ID_EditionFlagHidden: u32 = 0x45BD;
pub const ID_EditionFlagDefault: u32 = 0x45DB;
pub const ID_EditionFlagOrdered: u32 = 0x45DD;
pub const ID_EditionDisplay: u32 = 0x4520;
pub const ID_EditionString: u32 = 0x4521;
pub const ID_EditionLanguageIETF: u32 = 0x45E4;
pub const ID_ChapterAtom: u32 = 0xB6;
pub const ID_ChapterUID: u32 = 0x73C4;
pub const ID_ChapterStringUID: u32 = 0x5654;
pub const ID_ChapterTimeStart: u32 = 0x91;
pub const ID_ChapterTimeEnd: u32 = 0x92;
pub const ID_ChapterFlagHidden: u32 = 0x98;
pub const ID_ChapterFlagEnabled: u32 = 0x4598;
pub const ID_ChapterSegmentUUID: u32 = 0x6E67;
pub const ID_ChapterSkipType: u32 = 0x4588;
pub const ID_ChapterSegmentEditionUID: u32 = 0x6EBC;
pub const ID_ChapterPhysicalEquiv: u32 = 0x63C3;
pub const ID_ChapterTrack: u32 = 0x8F;
pub const ID_ChapterTrackUID: u32 = 0x89;
pub const ID_ChapterDisplay: u32 = 0x80;
pub const ID_ChapString: u32 = 0x85;
pub const ID_ChapLanguage: u32 = 0x437C;
pub const ID_ChapLanguageBCP47: u32 = 0x437D;
pub const ID_ChapCountry: u32 = 0x437E;
pub const ID_ChapProcess: u32 = 0x6944;
pub const ID_ChapProcessCodecID: u32 = 0x6955;
pub const ID_ChapProcessPrivate: u32 = 0x450D;
pub const ID_ChapProcessCommand: u32 = 0x6911;
pub const ID_ChapProcessTime: u32 = 0x6922;
pub const ID_ChapProcessData: u32 = 0x6933;
pub const ID_Tags: u32 = 0x1254C367;
pub const ID_Tag: u32 = 0x7373;
pub const ID_Targets: u32 = 0x63C0;
pub const ID_TargetTypeValue: u32 = 0x68CA;
pub const ID_TargetType: u32 = 0x63CA;
pub const ID_TagTrackUID: u32 = 0x63C5;
pub const ID_TagEditionUID: u32 = 0x63C9;
pub const ID_TagChapterUID: u32 = 0x63C4;
pub const ID_TagAttachmentUID: u32 = 0x63C6;
pub const ID_SimpleTag: u32 = 0x67C8;
pub const ID_TagName: u32 = 0x45A3;
pub const ID_TagLanguage: u32 = 0x447A;
pub const ID_TagLanguageBCP47: u32 = 0x447B;
pub const ID_TagDefault: u32 = 0x4484;
pub const ID_TagDefaultBogus: u32 = 0x44B4; // Deprecated
pub const ID_TagString: u32 = 0x4487;
pub const ID_TagBinary: u32 = 0x4485;
