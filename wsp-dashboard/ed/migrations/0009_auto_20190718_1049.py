# Generated by Django 2.1.1 on 2019-07-18 17:49

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ed', '0008_auto_20190718_1047'),
    ]

    operations = [
        migrations.AlterField(
            model_name='educationalgoal',
            name='courses',
            field=models.ManyToManyField(limit_choices_to={'student__username': 'self__student__username'}, to='ed.EDCourse'),
        ),
    ]
