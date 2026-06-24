-- =====================================================================
-- ChezMoi — Données de simulation (Gabon)
-- Équipements + hôtels / restaurants / activités.
-- Images : picsum.photos (placeholders déterministes, toujours dispo).
-- Réexécutable : on vide le catalogue avant d'insérer.
-- =====================================================================

-- ---- Équipements / services (options de filtre) --------------------
insert into public.amenities (key, label, applies_to, sort_order) values
  ('wifi',             'Wi-Fi',             '{hotel,restaurant,activity}', 1),
  ('parking',          'Parking',           '{hotel,restaurant,activity}', 2),
  ('pool',             'Piscine',           '{hotel}',                     3),
  ('breakfast',        'Petit-déjeuner',    '{hotel}',                     4),
  ('air_conditioning', 'Climatisation',     '{hotel,restaurant}',          5),
  ('restaurant',       'Restaurant',        '{hotel}',                     6),
  ('bar',              'Bar',               '{hotel,restaurant}',          7),
  ('beach_access',     'Accès plage',       '{hotel,activity}',            8),
  ('airport_shuttle',  'Navette aéroport',  '{hotel}',                     9),
  ('terrace',          'Terrasse',          '{restaurant}',               10),
  ('family_friendly',  'Familial',          '{hotel,restaurant,activity}',11),
  ('guide',            'Guide',             '{activity}',                 12)
on conflict (key) do update
  set label = excluded.label,
      applies_to = excluded.applies_to,
      sort_order = excluded.sort_order;

-- ---- Catalogue (reset puis insert) ---------------------------------
delete from public.places;

-- ============ HÔTELS (prix / nuit) ============
insert into public.places
  (category, title, public_code, description, subtype, price, price_unit,
   star_rating, guest_rating, review_count, max_guests, address, neighborhood, city,
   latitude, longitude, cover_image_url, image_urls, amenities, details, is_featured, view_count)
values
  ('hotel', 'Hôtel boutique bord de mer', 'GA-LBV-H01',
   'Chambres modernes face à l''océan, idéales séjours affaires et week-ends à Libreville.',
   'hotel', 82000, 'night', 4, 8.6, 184, 2,
   'Boulevard de la Mer', 'Batterie IV', 'Libreville',
   0.4162, 9.4325,
   'https://picsum.photos/seed/ga-h01/800/600',
   array['https://picsum.photos/seed/ga-h01a/800/600','https://picsum.photos/seed/ga-h01b/800/600'],
   array['Wi-Fi','Petit-déjeuner','Climatisation','Parking','Piscine'],
   '{}'::jsonb, true, 184),

  ('hotel', 'Auberge centrale pour voyageurs', 'GA-POG-H02',
   'Auberge simple et propre au centre de Port-Gentil, chambres privées et dortoirs.',
   'hostel', 24000, 'night', 2, 7.8, 96, 4,
   'Avenue Savorgnan de Brazza', 'Centre-ville', 'Port-Gentil',
   -0.7193, 8.7815,
   'https://picsum.photos/seed/ga-h02/800/600',
   array['https://picsum.photos/seed/ga-h02a/800/600'],
   array['Wi-Fi','Restaurant','Climatisation'],
   '{}'::jsonb, false, 96),

  ('hotel', 'Motel route nationale', 'GA-FCV-H03',
   'Étape pratique à Franceville : parking sécurisé et arrivée tardive possible.',
   'motel', 36000, 'night', 3, 7.4, 71, 2,
   'Route nationale', 'Potos', 'Franceville',
   -1.6333, 13.5833,
   'https://picsum.photos/seed/ga-h03/800/600',
   array['https://picsum.photos/seed/ga-h03a/800/600'],
   array['Parking','Climatisation','Restaurant'],
   '{}'::jsonb, false, 71),

  ('hotel', 'Maison d''hôtes familiale', 'GA-OYM-H04',
   'Accueil familial chaleureux, idéal pour de courts séjours à Oyem.',
   'guesthouse', 31000, 'night', null, 8.1, 58, 3,
   null, 'Akoakam', 'Oyem',
   1.5995, 11.5793,
   'https://picsum.photos/seed/ga-h04/800/600',
   array['https://picsum.photos/seed/ga-h04a/800/600'],
   array['Wi-Fi','Petit-déjeuner','Parking'],
   '{}'::jsonb, false, 58),

  ('hotel', 'Resort lagune Pointe Denis', 'GA-PDN-H05',
   'Bungalows pieds dans l''eau face à la lagune, à 20 min en bateau de Libreville.',
   'resort', 145000, 'night', 5, 9.0, 132, 4,
   'Presqu''île', 'Pointe Denis', 'Pointe Denis',
   0.3600, 9.3200,
   'https://picsum.photos/seed/ga-h05/800/600',
   array['https://picsum.photos/seed/ga-h05a/800/600','https://picsum.photos/seed/ga-h05b/800/600'],
   array['Wi-Fi','Piscine','Restaurant','Bar','Accès plage','Navette aéroport'],
   '{}'::jsonb, true, 132);

-- ============ RESTAURANTS (prix / personne) ============
insert into public.places
  (category, title, public_code, description, subtype, price, price_unit,
   star_rating, guest_rating, review_count, max_guests, address, neighborhood, city,
   latitude, longitude, cover_image_url, image_urls, amenities, details, is_featured, view_count)
values
  ('restaurant', 'Le Phare du Large', 'GA-LBV-R01',
   'Poissons et fruits de mer frais en bord de mer, spécialités gabonaises.',
   'Poisson & fruits de mer', 15000, 'person', null, 8.8, 240, 6,
   'Bord de Mer', 'Quartier Louis', 'Libreville',
   0.3920, 9.4530,
   'https://picsum.photos/seed/ga-r01/800/600',
   array['https://picsum.photos/seed/ga-r01a/800/600'],
   array['Wi-Fi','Climatisation','Bar','Terrasse'],
   '{"cuisine":"Gabonaise","opening_hours":"12h - 23h"}'::jsonb, true, 240),

  ('restaurant', 'Chez Tantine', 'GA-LBV-R02',
   'Cuisine africaine généreuse et conviviale, plats du jour à petit prix.',
   'Cuisine africaine', 8000, 'person', null, 8.2, 165, 4,
   'Avenue de Cointet', 'Nombakélé', 'Libreville',
   0.3950, 9.4570,
   'https://picsum.photos/seed/ga-r02/800/600',
   array['https://picsum.photos/seed/ga-r02a/800/600'],
   array['Familial','Terrasse'],
   '{"cuisine":"Africaine","opening_hours":"11h - 22h"}'::jsonb, false, 165),

  ('restaurant', 'La Terrasse', 'GA-POG-R03',
   'Grillades et cuisine internationale avec vue, ambiance détendue.',
   'Grill & international', 18000, 'person', null, 8.0, 98, 8,
   'Boulevard du Bord de Mer', 'Centre', 'Port-Gentil',
   -0.7160, 8.7840,
   'https://picsum.photos/seed/ga-r03/800/600',
   array['https://picsum.photos/seed/ga-r03a/800/600'],
   array['Wi-Fi','Climatisation','Bar','Terrasse'],
   '{"cuisine":"Internationale","opening_hours":"12h - 00h"}'::jsonb, false, 98),

  ('restaurant', 'Saveurs d''Oyem', 'GA-OYM-R04',
   'Petite adresse locale, plats traditionnels du nord du Gabon.',
   'Cuisine locale', 6000, 'person', null, 7.6, 54, 4,
   'Marché central', 'Centre', 'Oyem',
   1.5990, 11.5800,
   'https://picsum.photos/seed/ga-r04/800/600',
   array['https://picsum.photos/seed/ga-r04a/800/600'],
   array['Familial'],
   '{"cuisine":"Locale","opening_hours":"11h - 21h"}'::jsonb, false, 54);

-- ============ ACTIVITÉS (prix / personne) ============
insert into public.places
  (category, title, public_code, description, subtype, price, price_unit,
   star_rating, guest_rating, review_count, max_guests, address, neighborhood, city,
   latitude, longitude, cover_image_url, image_urls, amenities, details, is_featured, view_count)
values
  ('activity', 'Safari Parc national de la Lopé', 'GA-LPE-A01',
   'Observation de la faune (gorilles, éléphants de forêt) au cœur de la Lopé.',
   'Safari', 45000, 'person', null, 9.1, 210, 8,
   'Parc de la Lopé', null, 'Lopé',
   -0.2000, 11.5900,
   'https://picsum.photos/seed/ga-a01/800/600',
   array['https://picsum.photos/seed/ga-a01a/800/600','https://picsum.photos/seed/ga-a01b/800/600'],
   array['Guide','Familial'],
   '{"duration":"Journée","difficulty":"Modérée"}'::jsonb, true, 210),

  ('activity', 'Journée plage à Pointe Denis', 'GA-PDN-A02',
   'Traversée en bateau et journée détente sur les plages de Pointe Denis.',
   'Plage & détente', 20000, 'person', null, 8.5, 175, 10,
   'Embarcadère Michel Marine', null, 'Pointe Denis',
   0.3600, 9.3200,
   'https://picsum.photos/seed/ga-a02/800/600',
   array['https://picsum.photos/seed/ga-a02a/800/600'],
   array['Accès plage','Familial'],
   '{"duration":"Journée","difficulty":"Facile"}'::jsonb, false, 175),

  ('activity', 'Parc national de Loango', 'GA-LGO-A03',
   'Safari côtier unique : hippopotames surfeurs, baleines et forêt.',
   'Safari', 90000, 'person', null, 9.3, 142, 6,
   'Loango', null, 'Loango',
   -2.1000, 9.6000,
   'https://picsum.photos/seed/ga-a03/800/600',
   array['https://picsum.photos/seed/ga-a03a/800/600'],
   array['Guide'],
   '{"duration":"2 jours","difficulty":"Modérée"}'::jsonb, true, 142),

  ('activity', 'Randonnée Chutes de Kongou', 'GA-IVD-A04',
   'Trek vers les impressionnantes chutes de Kongou dans le parc de l''Ivindo.',
   'Randonnée', 35000, 'person', null, 8.7, 88, 8,
   'Parc de l''Ivindo', null, 'Ivindo',
   0.3000, 12.6000,
   'https://picsum.photos/seed/ga-a04/800/600',
   array['https://picsum.photos/seed/ga-a04a/800/600'],
   array['Guide'],
   '{"duration":"Journée","difficulty":"Difficile"}'::jsonb, false, 88),

  ('activity', 'Visite guidée de Libreville', 'GA-LBV-A05',
   'Découverte de la capitale : marché du Mont-Bouët, bord de mer et musées.',
   'Visite de ville', 12000, 'person', null, 7.9, 63, 12,
   'Centre-ville', null, 'Libreville',
   0.3920, 9.4540,
   'https://picsum.photos/seed/ga-a05/800/600',
   array['https://picsum.photos/seed/ga-a05a/800/600'],
   array['Guide','Familial'],
   '{"duration":"Demi-journée","difficulty":"Facile"}'::jsonb, false, 63);
