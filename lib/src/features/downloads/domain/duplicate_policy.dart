enum DuplicatePolicy {
  rename,
  overwrite,
  skip,
  resume,
}

String duplicatePolicyLabelFa(DuplicatePolicy value) => switch (value) {
      DuplicatePolicy.rename => 'تغییر نام خودکار',
      DuplicatePolicy.overwrite => 'جایگزینی فایل',
      DuplicatePolicy.skip => 'دانلود نکن',
      DuplicatePolicy.resume => 'ادامه فایل موجود',
    };
