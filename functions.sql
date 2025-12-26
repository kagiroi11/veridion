
-- gamified streak system
create or replace function update_streak (p_user uuid) returns void as $$
begin
  if (select last_emergency_withdrawal from streaks where user_id = p_user) = current_date then
    update streaks set streak_days = 0 where user_id = p_user;
  else
    update streaks set streak_days = streak_days + 1 where user_id = p_user;
  end if;
end;
$$ language plpgsql;


-- leaderboard system
create or replace function calculate_leaderboard()
returns void as $$
begin
  update leaderboard l
  set leaderboard_score =
    s.streak_days * l.saving_percentage
  from streaks s
  where l.user_id = s.user_id;
end;
$$ language plpgsql;

-- predictive analysis
create or replace function predict_savings(p_user uuid, months int)
returns text as $$
declare
  avg_saving numeric;
begin
  select avg(amount) into avg_saving
  from transactions
  where user_id = p_user and type = 'income';

  return 'At your current rate, you may save ₹' ||
         (avg_saving * months) ||
         ' in ' || months || ' months.';
end;
$$ language plpgsql;


-- motivational notifications
create or replace function generate_notification(p_user uuid)
returns void as $$
declare
  streak int;
  debt numeric;
  msg text;
begin
  select streak_days into streak from streaks where user_id = p_user;
  select debt_amount into debt from financial_summary where user_id = p_user;

  if streak >= 7 then
    msg := 'Great job! You maintained your emergency fund for ' || streak || ' days!';
  elsif debt > 0 then
    msg := 'Be careful! Your debt is increasing. Try to control expenses.';
  else
    msg := 'You are doing well. Keep saving consistently!';
  end if;

  insert into notifications(user_id, message, created_at)
  values (p_user, msg, now());
end;
$$ language plpgsql;
