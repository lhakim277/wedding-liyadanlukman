-- ==============================================================================
-- DATABASE SCHEMA: WEDDING INVITATION (SUPABASE / POSTGRESQL)
-- Website: The Wedding of Liya & Lukman
-- Acara: Resepsi & Akad — 6 September 2026
-- ==============================================================================
-- Petunjuk Penggunaan di Supabase:
-- 1. Buka https://supabase.com/dashboard/project/_/sql
-- 2. Buat "New Query", paste seluruh isi file ini, lalu klik "RUN".
-- 3. Script ini aman dijalankan berulang kali (Idempotent / Drop If Exists).
-- ==============================================================================

-- Aktifkan ekstensi UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. TABEL: guests (Master Data Tamu Undangan & URL Personal)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(30),
    category VARCHAR(100) DEFAULT 'Reguler', -- 'Keluarga', 'Sahabat', 'VIP', 'Rekan Kerja'
    pax_allocated INT NOT NULL DEFAULT 1 CHECK (pax_allocated > 0),
    is_opened BOOLEAN NOT NULL DEFAULT false,
    opened_at TIMESTAMPTZ,
    open_count INT NOT NULL DEFAULT 0,
    custom_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guests_slug ON public.guests(slug);
CREATE INDEX IF NOT EXISTS idx_guests_category ON public.guests(category);

-- ==============================================================================
-- 2. TABEL: wishes (Doa, Ucapan, dan Konfirmasi Kehadiran)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.wishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES public.guests(id) ON DELETE SET NULL,
    sender_name VARCHAR(255) NOT NULL,
    attendance VARCHAR(20) DEFAULT 'yes', -- 'yes' (Hadir) / 'no' (Tidak Hadir)
    message TEXT NOT NULL,
    is_visible BOOLEAN NOT NULL DEFAULT true,
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    likes_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pastikan kolom attendance selalu ada jika tabel sudah pernah dibuat sebelumnya
ALTER TABLE public.wishes ADD COLUMN IF NOT EXISTS attendance VARCHAR(20) DEFAULT 'yes';

CREATE INDEX IF NOT EXISTS idx_wishes_created_at ON public.wishes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wishes_visibility ON public.wishes(is_visible, is_pinned);

-- ==============================================================================
-- 3. TABEL: rsvps (Data Detail Kehadiran Tamu)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES public.guests(id) ON DELETE SET NULL,
    guest_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('attending', 'not_attending', 'tentative')),
    pax_attending INT NOT NULL DEFAULT 1 CHECK (pax_attending >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rsvps_guest_id ON public.rsvps(guest_id);
CREATE INDEX IF NOT EXISTS idx_rsvps_status ON public.rsvps(status);

-- ==============================================================================
-- 4. TABEL: gallery_items (Galeri Foto Pernikahan)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.gallery_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255),
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    alt_text VARCHAR(255) DEFAULT 'Foto Pernikahan Liya & Lukman',
    aspect_ratio VARCHAR(20) DEFAULT 'square' CHECK (aspect_ratio IN ('square', 'landscape', 'portrait', 'wide')),
    is_wide BOOLEAN NOT NULL DEFAULT false,
    object_position VARCHAR(50) DEFAULT 'center 50%',
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gallery_sort ON public.gallery_items(is_active, sort_order ASC);

-- ==============================================================================
-- 5. TABEL: wedding_events (Jadwal Acara & Lokasi)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.wedding_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_tag VARCHAR(100) NOT NULL, -- 'Resepsi', 'Akad Nikah'
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    timezone VARCHAR(10) NOT NULL DEFAULT 'WIB',
    venue_name VARCHAR(255) NOT NULL,
    venue_address TEXT NOT NULL,
    maps_url TEXT NOT NULL,
    calendar_url TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 6. TABEL: gift_accounts (Rekening & Alamat Kado Fisik)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.gift_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(30) NOT NULL CHECK (type IN ('bank', 'ewallet', 'physical_address')),
    provider_name VARCHAR(100) NOT NULL, -- 'Bank BCA', 'Bank BRI', 'KIRIM KADO FISIK'
    account_number TEXT NOT NULL,
    account_holder VARCHAR(255) NOT NULL,
    qr_code_url TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 7. TABEL: wedding_settings (Konten Global & Profil Mempelai)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.wedding_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_title VARCHAR(255) NOT NULL DEFAULT 'Liya & Lukman',
    wedding_date_text VARCHAR(100) NOT NULL DEFAULT 'Minggu, 6 September 2026',
    wedding_target_timestamp TIMESTAMPTZ NOT NULL DEFAULT '2026-09-06 08:00:00+07',
    bride_full_name VARCHAR(255) NOT NULL DEFAULT 'Miinatul Mauliyati Zahroh, S.K.M',
    bride_nickname VARCHAR(100) NOT NULL DEFAULT 'liya',
    bride_parents TEXT NOT NULL DEFAULT 'Bapak H. Mafadil & Ibu Hj. Siti Nurfaidah',
    groom_full_name VARCHAR(255) NOT NULL DEFAULT 'Lukman Hakim, S.Mat',
    groom_nickname VARCHAR(100) NOT NULL DEFAULT 'Lukman',
    groom_parents TEXT NOT NULL DEFAULT 'Bapak Hasyim & Ibu Umaiyah',
    cover_photo_url TEXT DEFAULT '/wedding/cover-ref.jpg',
    music_url TEXT DEFAULT '/music/Westlife - Nothing''s Going to Change My Love For You.mp3',
    opening_quote TEXT,
    verse_quote TEXT,
    verse_source VARCHAR(100) DEFAULT 'QS. Ar - Rum 21',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
-- Mengaktifkan RLS dan memberikan izin akses publik (Anon)
ALTER TABLE public.guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wedding_settings ENABLE ROW LEVEL SECURITY;

-- 8.1 Policies untuk wishes
DROP POLICY IF EXISTS "Public can view visible wishes" ON public.wishes;
DROP POLICY IF EXISTS "Public can post wishes" ON public.wishes;
DROP POLICY IF EXISTS "Allow public read wishes" ON public.wishes;
DROP POLICY IF EXISTS "Allow public insert to wishes" ON public.wishes;

CREATE POLICY "Allow public read wishes" 
ON public.wishes FOR SELECT 
TO anon, authenticated 
USING (is_visible = true);

CREATE POLICY "Allow public insert to wishes" 
ON public.wishes FOR INSERT 
TO anon, authenticated 
WITH CHECK (true);

-- 8.2 Policies untuk guests
DROP POLICY IF EXISTS "Public can read own guest data by slug" ON public.guests;
CREATE POLICY "Public can read own guest data by slug" 
ON public.guests FOR SELECT 
TO anon, authenticated 
USING (true);

-- 8.3 Policies untuk rsvps
DROP POLICY IF EXISTS "Public can view RSVPs" ON public.rsvps;
DROP POLICY IF EXISTS "Public can submit RSVP" ON public.rsvps;

CREATE POLICY "Public can view RSVPs" 
ON public.rsvps FOR SELECT 
TO anon, authenticated 
USING (true);

CREATE POLICY "Public can submit RSVP" 
ON public.rsvps FOR INSERT 
TO anon, authenticated 
WITH CHECK (true);

-- 8.4 Policies untuk Read-Only (Galeri, Events, Gifts, Settings)
DROP POLICY IF EXISTS "Public can view active gallery items" ON public.gallery_items;
CREATE POLICY "Public can view active gallery items" 
ON public.gallery_items FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

DROP POLICY IF EXISTS "Public can view active wedding events" ON public.wedding_events;
CREATE POLICY "Public can view active wedding events" 
ON public.wedding_events FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

DROP POLICY IF EXISTS "Public can view active gift accounts" ON public.gift_accounts;
CREATE POLICY "Public can view active gift accounts" 
ON public.gift_accounts FOR SELECT 
TO anon, authenticated 
USING (is_active = true);

DROP POLICY IF EXISTS "Public can view wedding settings" ON public.wedding_settings;
CREATE POLICY "Public can view wedding settings" 
ON public.wedding_settings FOR SELECT 
TO anon, authenticated 
USING (true);

-- ==============================================================================
-- 9. SUPABASE REALTIME REPLICATION (Agar Live Update Otomatis)
-- ==============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'wishes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.wishes;
    END IF;
END $$;

-- ==============================================================================
-- 10. INITIAL SEED DATA
-- ==============================================================================
-- Data awal rangkaian acara (Resepsi)
INSERT INTO public.wedding_events (
    event_tag,
    event_date,
    start_time,
    end_time,
    venue_name,
    venue_address,
    maps_url,
    sort_order
) VALUES (
    'Resepsi',
    '2026-09-06',
    '16:00:00',
    '21:00:00',
    'Kediaman Mempelai Wanita',
    'Jl. M. Siban Gg Purwasari II No 172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144',
    'https://maps.app.goo.gl/dUms5Z9cxpoVXWvk7',
    1
) ON CONFLICT DO NOTHING;

-- Data rekening & kado
INSERT INTO public.gift_accounts (type, provider_name, account_number, account_holder, sort_order)
VALUES 
('bank', 'Bank BCA', '7645012976', 'Lukman Hakim', 1),
('physical_address', 'KIRIM KADO FISIK', 'Jl. M. Siban Bojong Poncol No.172, RT.002/RW.008, Kunciran Indah, Kec. Pinang, Kota Tangerang, Banten 15144', 'Penerima: Liya & Lukman', 2)
ON CONFLICT DO NOTHING;
