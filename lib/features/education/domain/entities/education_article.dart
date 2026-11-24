enum EducationCategory { organic, inorganic, hazardous }

extension EducationCategoryLabel on EducationCategory {
  String get label => switch (this) {
    EducationCategory.organic => 'Organik',
    EducationCategory.inorganic => 'Anorganik',
    EducationCategory.hazardous => 'B3',
  };
}

class EducationArticle {
  const EducationArticle({
    required this.slug,
    required this.title,
    required this.summary,
    required this.category,
    required this.readingMinutes,
    required this.content,
    required this.steps,
  });

  final String slug;
  final String title;
  final String summary;
  final EducationCategory category;
  final int readingMinutes;
  final String content;
  final List<String> steps;

  static const articles = [
    EducationArticle(
      slug: 'sisa-dapur-jadi-kompos',
      title: 'Ubah sisa dapur menjadi kompos',
      summary: 'Cara sederhana mengolah sisa buah dan sayur di rumah.',
      category: EducationCategory.organic,
      readingMinutes: 3,
      content:
          'Sisa sayur, buah, ampas kopi, dan daun kering dapat diolah menjadi '
          'kompos. Pisahkan dari daging, minyak, dan bahan kimia agar proses '
          'pengomposan lebih bersih dan tidak mengundang hama.',
      steps: [
        'Cacah bahan organik agar lebih cepat terurai.',
        'Campur bahan basah dengan daun kering atau kardus tanpa tinta.',
        'Jaga kelembapan seperti spons yang diperas dan aduk berkala.',
      ],
    ),
    EducationArticle(
      slug: 'pilah-sampah-organik',
      title: 'Kenali sampah organik',
      summary: 'Bedakan sisa yang mudah terurai dari sampah lainnya.',
      category: EducationCategory.organic,
      readingMinutes: 2,
      content:
          'Sampah organik berasal dari makhluk hidup dan dapat terurai secara '
          'alami. Contohnya kulit buah, sisa sayuran, daun, dan ampas kopi. '
          'Pemilahan dari rumah mengurangi sampah yang berakhir di TPA.',
      steps: [
        'Sediakan wadah khusus sampah organik.',
        'Tiriskan sisa makanan agar tidak terlalu basah.',
        'Olah menjadi kompos atau setorkan ke pengolah organik.',
      ],
    ),
    EducationArticle(
      slug: 'siapkan-botol-plastik',
      title: 'Siapkan botol plastik sebelum disetor',
      summary: 'Bersihkan, keringkan, dan pisahkan komponen botol.',
      category: EducationCategory.inorganic,
      readingMinutes: 2,
      content:
          'Botol PET yang bersih dan kering lebih mudah ditangani di fasilitas '
          'daur ulang. Pastikan jenis plastik diterima oleh bank sampah tujuan '
          'karena aturan dapat berbeda antar mitra.',
      steps: [
        'Kosongkan isi botol dan bilas bila perlu.',
        'Keringkan botol, lalu pipihkan untuk menghemat ruang.',
        'Pisahkan tutup dan label sesuai aturan bank sampah setempat.',
      ],
    ),
    EducationArticle(
      slug: 'kardus-siap-daur-ulang',
      title: 'Kardus yang siap didaur ulang',
      summary: 'Jaga kardus tetap kering dan bebas dari sisa makanan.',
      category: EducationCategory.inorganic,
      readingMinutes: 2,
      content:
          'Kardus dapat digunakan kembali atau didaur ulang menjadi produk '
          'kertas. Kardus berminyak dan basah biasanya sulit diproses, jadi '
          'pisahkan bagian yang bersih dari bagian yang tercemar.',
      steps: [
        'Lepaskan selotip dan bahan pelindung yang tidak diterima.',
        'Pastikan kardus kering dan tidak berbau.',
        'Lipat rata dan simpan di tempat yang tidak terkena hujan.',
      ],
    ),
    EducationArticle(
      slug: 'baterai-termasuk-b3',
      title: 'Baterai bekas termasuk sampah B3',
      summary: 'Simpan terpisah dan jangan membuang baterai ke tempat sampah.',
      category: EducationCategory.hazardous,
      readingMinutes: 2,
      content:
          'Baterai dan lampu tertentu dapat mengandung bahan berbahaya. '
          'Jangan dibakar, dibongkar, atau dicampur ke sampah rumah tangga. '
          'Cari titik pengumpulan khusus yang menerima limbah B3 rumah tangga.',
      steps: [
        'Simpan baterai bekas dalam wadah kering dan tertutup.',
        'Jauhkan dari panas, air, anak-anak, dan hewan peliharaan.',
        'Antarkan ke fasilitas pengumpulan B3 yang resmi.',
      ],
    ),
    EducationArticle(
      slug: 'kelola-limbah-elektronik',
      title: 'Kelola limbah elektronik dengan aman',
      summary: 'Ponsel dan kabel rusak memerlukan jalur pengumpulan khusus.',
      category: EducationCategory.hazardous,
      readingMinutes: 3,
      content:
          'Perangkat elektronik dapat mengandung material yang perlu ditangani '
          'secara khusus. Gunakan program take-back produsen, drop box resmi, '
          'atau mitra pengolah limbah elektronik. Hapus data pribadi sebelum '
          'menyerahkan perangkat.',
      steps: [
        'Cadangkan lalu hapus data dari perangkat yang masih dapat dinyalakan.',
        'Lepaskan baterai hanya jika memang dirancang untuk dilepas.',
        'Jangan membongkar perangkat; serahkan ke pengumpul resmi.',
      ],
    ),
  ];

  static EducationArticle? bySlug(String slug) {
    for (final article in articles) {
      if (article.slug == slug) {
        return article;
      }
    }
    return null;
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  static const questions = [
    QuizQuestion(
      question: 'Mana contoh sampah organik?',
      options: ['Kulit pisang', 'Botol kaca', 'Baterai bekas'],
      correctIndex: 0,
      explanation: 'Kulit buah mudah terurai dan dapat diolah menjadi kompos.',
    ),
    QuizQuestion(
      question: 'Apa yang sebaiknya dilakukan pada botol PET sebelum disetor?',
      options: [
        'Biarkan masih berisi cairan',
        'Kosongkan, bilas bila perlu, lalu keringkan',
        'Campur dengan sampah dapur',
      ],
      correctIndex: 1,
      explanation: 'Botol yang kosong dan kering lebih mudah dipilah.',
    ),
    QuizQuestion(
      question: 'Bagaimana cara menyimpan baterai bekas?',
      options: [
        'Campur dengan sampah biasa',
        'Rendam di dalam air',
        'Simpan kering dan setorkan ke pengumpul B3',
      ],
      correctIndex: 2,
      explanation: 'Baterai termasuk sampah B3 dan perlu penanganan khusus.',
    ),
    QuizQuestion(
      question: 'Mengapa kardus sebaiknya disimpan dalam keadaan kering?',
      options: [
        'Agar lebih mudah didaur ulang',
        'Supaya berubah menjadi plastik',
        'Agar tidak perlu dipilah',
      ],
      correctIndex: 0,
      explanation: 'Kardus basah atau berminyak lebih sulit diproses ulang.',
    ),
    QuizQuestion(
      question: 'Ke mana limbah elektronik rumah tangga sebaiknya dibawa?',
      options: [
        'Ke saluran air',
        'Ke titik pengumpulan atau pengolah resmi',
        'Dibakar di halaman',
      ],
      correctIndex: 1,
      explanation:
          'Pengumpulan resmi membantu mencegah pencemaran dan paparan.',
    ),
  ];
}
