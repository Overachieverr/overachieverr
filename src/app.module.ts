import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { UserModule } from './user/user.module';

@Module({
  imports: [ConfigModule.forRoot({
    load: [configuration],
  }), UserModule],
  controllers: [],
  providers: [],
})
export class AppModule {}
