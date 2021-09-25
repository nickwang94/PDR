clear;
%% [time, ax,ay,az,gx,gy,gz] = textread('state3.txt', '%n;%n;%n;%n;%n;%n;%n;');
[ax,ay,az,gx,gy,gz] = textread('state2.txt', '%n;%n;%n;%n;%n;%n;');
ax_avg = mean(ax);
ay_avg = mean(ay);
az_avg = mean(az) - 9.81;
gx_avg = mean(gx);
gy_avg = mean(gy);
gz_avg = mean(gz);

abias = [ax_avg, ay_avg, az_avg]
gbias = [gx_avg, gy_avg, gz_avg]

figure(1)
plot(ax - ax_avg)
figure(2)
plot(ay - ay_avg)
figure(3)
plot(az - 9.81 - az_avg)
figure(4)
plot(gx - gx_avg)
figure(5)
plot(gy - gx_avg)
figure(6)
plot(gz - gz_avg)