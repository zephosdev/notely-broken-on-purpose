insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111','ada@example.com'),
  ('22222222-2222-2222-2222-222222222222','grace@example.com');
insert into public.profiles (id, email, full_name, plan, stripe_customer_id) values
  ('11111111-1111-1111-1111-111111111111','ada@example.com','Ada Example','pro','cus_EXAMPLE0001'),
  ('22222222-2222-2222-2222-222222222222','grace@example.com','Grace Example','free',null);
insert into public.notes (user_id, body) values
  ('11111111-1111-1111-1111-111111111111','Ada private note: launch password is in 1Password'),
  ('22222222-2222-2222-2222-222222222222','Grace private note: churn list for Q4');
