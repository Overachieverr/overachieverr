import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './users/user.entity';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: '/app/db.sqlite3',
      synchronize: process.env.NODE_ENV !== "production",
      entities: [User],
    }),
    UsersModule,
  ],
})
export class AppModule {}
